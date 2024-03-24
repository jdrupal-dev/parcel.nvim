# parcel.nvim :package:

<img width="1699" alt="image" src="https://github.com/jdrupal-dev/parcel.nvim/assets/13871894/6cd5f30e-df26-4503-9d9a-077ab7f6163c">

## :lock: Requirements

- [jsonpath.nvim](https://github.com/phelipetls/jsonpath.nvim)

### Optional
- [cargo-outdated](https://github.com/kbknapp/cargo-outdated) - for cargo support.

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
  - Installed version shown in composer.json
  - New minor and/or major version(s) shown in composer.json
- NPM/Yarn
  - Installed version shown in package.json
  - New minor and/or major version(s) shown in package.json
- Cargo
  - [ ] TODO: Show installed version in Cargo.toml
  - New minor and/or major version(s) shown in Cargo.toml
