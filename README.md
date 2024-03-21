# parcel.nvim :package:

## :lock: Requirements

- [jsonpath.nvim](https://github.com/phelipetls/jsonpath.nvim)

## :package: Installation

Install this plugin using your favorite plugin manager, and then call
`require("parcel").setup()`.

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
    "jdrupal-dev/parcel.nvim",
    dependencies = {
      "phelipetls/jsonpath.nvim",
    },
    opts = {},
}
```
## :sparkles: Features

- [x] Show locked and new package versions in supported package managers.
- [ ] TODO: Search for packages and install directly from neovim.

**Supported package managers**
- Composer
- NPM/Yarn
