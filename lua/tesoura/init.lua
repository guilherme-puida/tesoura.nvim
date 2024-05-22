-- MIT License
-- Copyright (c) 2024 Guilherme Puida Moreira
local Tesoura = {}
local H = {}
local source = {}

---@class Snippet
---@field body string|string[]|fun(ft: string): string
---@field highlight boolean
---@field prefix string

---@class TesouraConfig
---@field highlight boolean
---@field ignored_filetypes string[]
---@field setup_autocmd boolean
---@field snippets table<string, Snippet[]>
---@field source_name string

---@class TesouraConfigParams
---@field highlight? boolean
---@field ignored_filetypes? string[]
---@field setup_autocmd? boolean
---@field snippets? table<string, Snippet[]>
---@field source_name? string

---@param config? TesouraConfigParams
Tesoura.setup = function(config)
  local complete_config = H.setup_config(config)
  H.apply_config(complete_config)
end

---@class TesouraConfig
Tesoura.config = {
  highlight = true,
  ignored_filetypes = {},
  setup_autocmd = false,
  snippets = {},
  source_name = 'tesoura',
}

Tesoura.register_source = function()
  H.cmp = require 'cmp'
  H.cmp.register_source(Tesoura.config.source_name, source)
end

H.default_config = vim.deepcopy(Tesoura.config)

---@param config? TesouraConfigParams
---@return TesouraConfig
H.setup_config = function(config)
  vim.validate { config = { config, 'table', true }}
  local complete_config = vim.tbl_deep_extend('force', vim.deepcopy(H.default_config), config or {})

  vim.validate {
    highlight = { complete_config.highlight, 'boolean' },
    ignored_filetypes = { complete_config.ignored_filetypes, 'table' },
    setup_autocmd = { complete_config.setup_autocmd, 'boolean' },
    snippets = { complete_config.snippets, 'table' },
    source_name = { complete_config.source_name, 'string' },
  }

  -- TODO: maybe validate if every individual snippet definition is valid.

  return complete_config
end

---@param config TesouraConfig
H.apply_config = function(config)
  Tesoura.config = config

  if config.setup_autocmd then
    vim.api.nvim_create_autocmd('FileType', {
      group = vim.api.nvim_create_augroup('tesoura_filetype_detect', { clear = true }),
      pattern = '*',
      callback = function(event)
        H.load_snippets_for_filetype(event.match)
      end,
    })
  end
end

---@type table<string, Snippet[]>
H.snippet_cache = {}

---@type table<string, boolean>
H.loaded_filetype = {}

---@param filetype string
H.load_snippets_for_filetype = function(filetype)
  local global_snippets = Tesoura.config.snippets['*'] or {}
  local filetype_snippets = Tesoura.config.snippets[filetype] or {}
  local snippets = vim.tbl_extend('force', global_snippets, filetype_snippets)
  H.snippet_cache[filetype] = snippets
  H.loaded_filetype[filetype] = true
end

---@return boolean
function source:is_available()
  return true
end

---@return string
function source:get_debug_name()
  return Tesoura.config.source_name
end

---@param callback fun(response: lsp.CompletionItem[]|nil)
function source:complete(_, callback)
  local filetype = vim.bo.filetype

  -- if the snippets haven't been loaded yet, load them.
  if not H.loaded_filetype[filetype] then
    H.load_snippets_for_filetype(filetype)
  end

  -- the snippets are already loaded, so just retrieve them from the cache.
  -- if the table is empty here, it means that there are no snippets configured
  -- for that filetype.
  local snippets = H.snippet_cache[filetype]
  if not snippets then return end

  ---@type lsp.CompletionItem[]
  local response = {}

  for _, snippet in ipairs(snippets) do
    local body = snippet.body

    if type(body) == 'table' then
      body = table.concat(body, '\n')
    elseif type(body) == 'function' then
      -- TODO: is passing the filetype really necessary?
      body = body(filetype)
    end

    ---@type lsp.CompletionItem
    local r = {
      label = snippet.prefix,
      insertText = body,
      insertTextMode = H.cmp.lsp.InsertTextMode.AdjustIndentation,
      kind = H.cmp.lsp.CompletionItemKind.Snippet,
      insertTextFormat = H.cmp.lsp.InsertTextFormat.Snippet,
      data = {
        prefix = snippet.prefix,
        body = body,
        highlight = snippet.highlight,
      },
    }

    table.insert(response, r)
  end

  callback(response)
end

---@param completion_item lsp.CompletionItem
---@param callback fun(completion_item: lsp.CompletionItem|nil)
function source:resolve(completion_item, callback)
  local data = completion_item.data or {}
  local preview = data.body

  -- we should highlight if any of those two match:
  -- 1. the snippet has highlight = true (independent of the global higlight option).
  -- 2. the global highlight is on and the snippet does not have highlight = false.
  local should_highlight = data.highlight or (
    Tesoura.config.highlight and data.highlight ~= false
  )

  -- format the documentation with a fenced markdown block if highlighting is enabled.
  if should_highlight then
    preview = string.format('```%s\n%s\n```', vim.bo.filetype, preview)
  end

  completion_item.documentation = {
    kind = H.cmp.lsp.MarkupKind.Markdown,
    value = preview,
  }

  callback(completion_item)
end

---@param completion_item lsp.CompletionItem
---@param callback fun(completion_item: lsp.CompletionItem|nil)
function source:execute(completion_item, callback)
  callback(completion_item)
end

return Tesoura
