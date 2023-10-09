# broot.nvim

[Broot] integration for [Neovim].

[Broot]: https://github.com/Canop/broot
[Neovim]: https://neovim.io/

## Usage

```lua
require("broot").broot()
```

## Roadmap

- [x] Launch in directory
- [x] Add extra CLI arguments to `broot`
- [ ] Documentation
- [ ] Add user commands
- [ ] Lazily initialize `nvim.toml` config file
- [ ] Verb precedence for Broot (may require upstream Broot changes)
- [ ] Netrw replacement
- [ ] Window size/placement customization
- [ ] Type annotations / type checking for Lua sources (may require upstream
  `lua-language-server` changes)
