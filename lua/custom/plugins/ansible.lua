-- Ansible and Jinja template support.
--
-- Neovim has no built-in detection for Ansible YAML or `.j2` templates. The
-- language server still attaches to plain `yaml`, but the dedicated
-- `yaml.ansible` filetype is what lets us add Ansible-specific ftplugins and
-- navigation without affecting every YAML file on the machine.

local function is_ansible_project(path)
  local dir = vim.fs.dirname(path)
  if not dir then return false end

  local marker = vim.fs.find({ 'ansible.cfg', '.ansible-lint', 'galaxy.yml', 'requirements.yml' }, {
    path = dir,
    upward = true,
    type = 'file',
  })[1]

  return marker ~= nil
end

local function first_line_is_vault(bufnr)
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then return false end

  local first = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1] or ''
  return first:match '^%$ANSIBLE_VAULT;' ~= nil
end

local function is_role_yaml(path)
  local subdir = path:match '/roles/[^/]+/([^/]+)/'
  if not subdir then return false end

  return subdir == 'tasks' or subdir == 'handlers' or subdir == 'defaults' or subdir == 'vars' or subdir == 'meta'
end

local function is_ansible_dir(path)
  for _, dir in ipairs { 'group_vars', 'host_vars', 'inventories', 'playbooks', 'molecule' } do
    if path:find('/' .. dir .. '/', 1, true) then return true end
  end

  -- `vars/` is generic enough that another kind of project could use it, so
  -- require an Ansible project marker for that one.
  if path:find('/vars/', 1, true) then return is_ansible_project(path) end

  return false
end

local function looks_like_playbook(bufnr)
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then return false end

  for _, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, 200, false)) do
    if line:match '^%s*%-%s+hosts%s*:' or line:match '^%s*%-%s+import_playbook%s*:' then return true end

    -- A play's `hosts:` is at the top level of the play (two spaces). A task
    -- argument named `hosts` is deeper and must not trigger detection.
    local indent = line:match '^%s*'
    if indent and #indent <= 4 and line:match '^%s*hosts%s*:' then return true end
  end

  return false
end

local function ansible_yaml(path, bufnr)
  if first_line_is_vault(bufnr) then return 'ansible-vault' end
  if is_role_yaml(path) or is_ansible_dir(path) then return 'yaml.ansible' end
  if is_ansible_project(path) and looks_like_playbook(bufnr) then return 'yaml.ansible' end

  return nil
end

-- Jinja templates normally show the Jinja tags but leave the rest of the file
-- unhighlighted. For each host syntax we create a parser alias backed by the
-- same jinja parser, and inject the host language into the `content` nodes
-- (the text between Jinja tags). The result is combined highlighting:
-- `jinja.json`, `jinja.ini`, `jinja.bash`, `jinja.yaml`, `jinja.xml`, ...
local jinja_parser_path
local jinja_variants = {}

local function ensure_jinja_variant(host)
  if jinja_variants[host] ~= nil then return jinja_variants[host] or nil end

  jinja_parser_path = jinja_parser_path or vim.api.nvim_get_runtime_file('parser/jinja.*', false)[1]
  if not jinja_parser_path then return nil end

  local alias = 'jinja_' .. host
  local ok = vim.treesitter.language.add(alias, { path = jinja_parser_path, symbol_name = 'jinja' })
  if not ok then return nil end

  vim.treesitter.language.register(alias, 'jinja.' .. host)
  vim.treesitter.query.set(alias, 'highlights', '; inherits: jinja\n')
  vim.treesitter.query.set(alias, 'injections', '; inherits: jinja\n((content) @injection.content (#set! injection.language "' .. host .. '"))')

  jinja_variants[host] = alias
  return alias
end

local template_hosts = {
  sh = 'bash',
  bash = 'bash',
  zsh = 'bash',
  json = 'json',
  ini = 'ini',
  yml = 'yaml',
  yaml = 'yaml',
  html = 'html',
  htm = 'html',
  xml = 'xml',
}

local systemd_units = {
  service = true,
  timer = true,
  socket = true,
  mount = true,
  automount = true,
  swap = true,
  target = true,
  path = true,
  slice = true,
  scope = true,
  device = true,
}

--- Pick the host language for a Jinja template from its name and contents.
---@param path string
---@param bufnr integer?
---@return string?
local function template_host(path, bufnr)
  local name = vim.fs.basename(path:lower())
  local base = name:gsub('%.j2$', ''):gsub('%.jinja2?$', '')
  local ext = base:match '%.([%w]+)$'

  -- Extensions that are unambiguous even for a new, empty file.
  if ext and template_hosts[ext] then return template_hosts[ext] end

  -- For generic `.j2`, `.conf.j2`, `.service.j2`, etc., look at the first few
  -- lines. This also catches the occasional XML file named `*.service.j2`.
  if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    local first_code
    local in_jinja_comment = false
    local in_xml_comment = false

    for _, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, 40, false)) do
      local trimmed = line:gsub('^%s+', '')

      if trimmed:match '^#!.*%f[%a]bash%f[%A]' or trimmed:match '^#!.*%f[%a]sh%f[%A]' or trimmed:match '^#!.*%f[%a]zsh%f[%A]' then return 'bash' end

      if trimmed:match '^<%?xml' then return 'xml' end
      if trimmed:match '^<!DOCTYPE%s+html' or trimmed:match '^<html' then return 'html' end
      if trimmed:match '^<[%w]' then return 'xml' end
      if trimmed:match '^%[[%w_.-]+%]%s*$' then return 'ini' end

      if in_jinja_comment or in_xml_comment then
        if in_jinja_comment and trimmed:find('#}', 1, true) then in_jinja_comment = false end
        if in_xml_comment and trimmed:find('-->', 1, true) then in_xml_comment = false end
      elseif trimmed:find('{#', 1, true) and not trimmed:find('#}', 1, true) then
        in_jinja_comment = true
      elseif trimmed:find('<!--', 1, true) and not trimmed:find('-->', 1, true) then
        in_xml_comment = true
      else
        local is_comment = trimmed == ''
          or trimmed:match '^#'
          or trimmed:match '^//'
          or trimmed:match '^%-%-'
          or (trimmed:find('{#', 1, true) and trimmed:find('#}', 1, true))
          or (trimmed:find('<!--', 1, true) and trimmed:find('-->', 1, true))
          or trimmed:match '^{%%.*%%}$'

        if not is_comment then
          first_code = trimmed
          break
        end
      end
    end

    if first_code then
      if first_code:match '^{' or first_code:match '^%[%s*[%[{"]' then return 'json' end
      if first_code:match '^%-%-%-' then return 'yaml' end
    end
  end

  if ext and systemd_units[ext] then return 'ini' end

  return nil
end

local function template_filetype(path, bufnr)
  local host = template_host(path, bufnr)
  if host and ensure_jinja_variant(host) then return 'jinja.' .. host end

  return 'jinja'
end

vim.filetype.add {
  extension = {
    j2 = 'jinja',
    jinja = 'jinja',
    jinja2 = 'jinja',
  },
  pattern = {
    ['.*%.yml'] = ansible_yaml,
    ['.*%.yaml'] = ansible_yaml,
    ['.*%.yml%.example'] = ansible_yaml,
    ['.*%.yaml%.example'] = ansible_yaml,
    ['.*%.j2'] = template_filetype,
    ['.*%.jinja'] = template_filetype,
    ['.*%.jinja2'] = template_filetype,
  },
}

local function exists(path) return vim.uv.fs_stat(path) ~= nil end

local function exists_with_template_suffix(path)
  if exists(path) then return path end

  for _, suffix in ipairs { '.j2', '.jinja', '.jinja2' } do
    if exists(path .. suffix) then return path .. suffix end
  end

  return nil
end

-- Resolve `gf` targets from Ansible tasks:
--   * include_tasks/import_tasks are relative to the current file
--   * template/copy sources live in the role's templates/ or files/ directory
--   * playbook-level file references are relative to the playbook's files/
function _G.AnsibleIncludeExpr(fname)
  if fname == '' or fname:find('{{', 1, true) or fname:find('{%', 1, true) then return fname end
  if fname:sub(1, 1) == '/' then return fname end

  local current = vim.api.nvim_buf_get_name(0)
  local candidates = {}

  if current ~= '' then
    current = vim.fs.abspath(current)
    local dir = vim.fs.dirname(current)
    table.insert(candidates, vim.fs.joinpath(dir, fname))
    table.insert(candidates, vim.fs.joinpath(dir, 'files', fname))
  end

  local role = current:match '^(.*/roles/[^/]+)/'
  if role then
    table.insert(candidates, vim.fs.joinpath(role, 'templates', fname))
    table.insert(candidates, vim.fs.joinpath(role, 'files', fname))
  end

  for _, candidate in ipairs(candidates) do
    local resolved = exists_with_template_suffix(candidate)
    if resolved then return resolved end
  end

  return fname
end

-- Neovim already maps yaml.ansible to the yaml parser, but make it explicit
-- so the parser still works if that default changes.
vim.treesitter.language.register('yaml', 'yaml.ansible')

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'yaml.ansible',
  callback = function(args)
    -- `yaml.ansible` inherits the built-in YAML ftplugin/indent file via the
    -- dot in its name; only the Ansible-specific navigation is added here.
    vim.bo[args.buf].includeexpr = 'v:lua.AnsibleIncludeExpr(v:fname)'
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'jinja', 'jinja.*' },
  callback = function(args)
    vim.bo[args.buf].commentstring = '{# %s #}'

    -- Manual `:set ft=jinja.yaml` (or changing filetype after the buffer was
    -- already highlighted) should still pick up the combined parser.
    local host = vim.bo[args.buf].filetype:match '^jinja%.(.+)$'
    if not host or not ensure_jinja_variant(host) then return end

    local alias = 'jinja_' .. host
    local highlighter = vim.treesitter.highlighter.active[args.buf]
    if highlighter and highlighter.tree:lang() == alias then return end

    if highlighter then vim.treesitter.stop(args.buf) end
    vim.treesitter.start(args.buf, alias)
  end,
})

-- vim: ts=2 sts=2 sw=2 et
