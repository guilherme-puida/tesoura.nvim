# :scissors: tesoura.nvim

**tesoura.nvim** is a snippet management plugin using the new native snippet
api (`:h vim.snippet`).

## Features

- Configure snippets using plain Lua tables.
- Dynamic snippets.
- [`nvim-cmp`] completion source.

## Requirements

- Neovim >= 0.10.0
- [`nvim-cmp`] (Optional, but recommended).

## Installation

Using `lazy.nvim`:

```lua
{
  'guilherme-puida/tesoura.nvim',
  opts = {} -- see the configuration section below.
}
```

## Configuration

**tesoura.nvim** comes with the following defaults:

```lua
{
  -- highlight snippet content on the documentation window.
  highlight = true,
  -- filetypes where snippets won't be setup.
  ignored_filetypes = {},
  -- set up autocmd to automatically initialize snippets when a new filetype is opened.
  setup_autocmd = false,
  -- your snippets!
  snippets = {},
  -- the nvim_cmp source name.
  source_name = 'tesoura',
}
```

## Configuring snippets

Snippets should be provided in the `snippets` key when calling the `setup` method.

A snippet is a Lua table containing at least a `prefix` and a `body`. The
prefix is what you type, and the body is what it expands to.

```lua
local snippet = {
  prefix = 'hello',
  body = 'world',
}
```

The `body` can be:

1. A `string`. The body will be inserted as-is.
2. A list of `string`s. Every element of the list will be inserted on a new
   line.
3. A function that returns a `string`. The function will be evaluated when the
   snippet hits the `nvim-cmp` completion dialog.

The `vim.snippet` api supports a subset of the [LSP snippet syntax], so you can
use tab stops inside the body.

The fact that snippets are just Lua code makes the system very flexible.

```lua
local snippet = {
  prefix = 'date',
  body = function() return tostring(os.date '%F') end,
}
```

The `snippets` configuration parameter is a table that maps filetypes to
snippet definitions. The `*` key applies to all filetypes (except those that
are explicitly ignored).

```lua
local snippets = {
  ['*'] = {
    { prefix = 'copyright', body = 'Copyright (c) 2024 Guilherme Puida Moreira' },
  },
  c = {
    { prefix = '#i', body = '#include "$1"$0' },
  }
}
```

## Roadmap

- [ ] Decouple core logic from `nvim-cmp`.
- [ ] Add tests.
- [ ] Better documentation.

## License

**tesoura.nvim** is licensed under the MIT License.

## Acknowledgments

- [garymjr/nvim-snippets](https://github.com/garymjr/nvim-snippets): gave me the idea to implement this.
- [echasnovski/mini.nvim](https://github.com/echasnovski/mini.nvim): for the plugin structure.

[`nvim-cmp`]: https://github.com/hrsh7th/nvim-cmp
[LSP snippet syntax]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#snippet_syntax
