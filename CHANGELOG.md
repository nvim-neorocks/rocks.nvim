# Changelog

## [1.0.1](https://github.com/nvim-neorocks/rocks.nvim/compare/v1.0.0...v1.0.1) (2023-11-22)


### Bug Fixes

* **operations:** only find dependencies of rocks that exist ([#21](https://github.com/nvim-neorocks/rocks.nvim/issues/21)) ([6d3810d](https://github.com/nvim-neorocks/rocks.nvim/commit/6d3810dfaa3eabd9a23fa433e0f308fc7b16102d))

## 1.0.0 (2023-11-20)


### ⚠ BREAKING CHANGES

* auto-setup + healthchecks + generate vimdocs ([#10](https://github.com/nvim-neorocks/rocks.nvim/issues/10))
* better `install()` function
* move code to nio asynchronous logic, implement `sync` command
* severely refactor internal logic, add support for updating plugins
* start codebase refactor

### ref

* better `install()` function ([740508b](https://github.com/nvim-neorocks/rocks.nvim/commit/740508b96ffc9419c60e4c158d74934d759cd344))


### Features

* add .luarc.json ([a89ee5f](https://github.com/nvim-neorocks/rocks.nvim/commit/a89ee5f401b158b0dfafc461d3adcb1170e8ecd2))
* add `:Rocks install` command ([9845021](https://github.com/nvim-neorocks/rocks.nvim/commit/9845021d3e5cac61f23655aef9c88217c823bc12))
* add `:Rocks` command via `plugin/` directory ([aa988aa](https://github.com/nvim-neorocks/rocks.nvim/commit/aa988aa6af5cd8c7d8097ff94889e12f134dedf1))
* add `.luacheckrc` ([9376ae2](https://github.com/nvim-neorocks/rocks.nvim/commit/9376ae2624ca0008f50f4807dccfec4957b6b026))
* add `toml-edit` dependency ([bd02c6f](https://github.com/nvim-neorocks/rocks.nvim/commit/bd02c6f65b0bc382711f7e638b51cc9f9e00d4c4))
* add `update()` command ([75061c9](https://github.com/nvim-neorocks/rocks.nvim/commit/75061c983d3ccfc30fd7346043a8de6d2eb51756))
* add installed plugins to `runtimepath` ([6132e0c](https://github.com/nvim-neorocks/rocks.nvim/commit/6132e0ca1aba426199d98d78db6a019e4f0fe07d))
* add Makefile and stylua.toml ([6e4eb7c](https://github.com/nvim-neorocks/rocks.nvim/commit/6e4eb7c25a3c20eaf9c41baa656420b986348782))
* add nui.nvim dependency to the manifest ([#18](https://github.com/nvim-neorocks/rocks.nvim/issues/18)) ([5faf2be](https://github.com/nvim-neorocks/rocks.nvim/commit/5faf2bed7362b71d6a00f89ddb428070ff0eb6bc))
* add proper error propagation in async contexts ([885c58b](https://github.com/nvim-neorocks/rocks.nvim/commit/885c58bccb0ea8b81f290928faffb8b09400c046))
* add UI to `update()` function ([006a75e](https://github.com/nvim-neorocks/rocks.nvim/commit/006a75e0897d94160ac5a92504a035a3dd43a83c))
* auto-setup + healthchecks + generate vimdocs ([#10](https://github.com/nvim-neorocks/rocks.nvim/issues/10)) ([920764d](https://github.com/nvim-neorocks/rocks.nvim/commit/920764d8f04121817ac6246c5f1b7e70ec813899))
* **bootstrap:** add Installation result detection ([#20](https://github.com/nvim-neorocks/rocks.nvim/issues/20)) ([bb532fb](https://github.com/nvim-neorocks/rocks.nvim/commit/bb532fb8f93323f90db581343105b0c1fa65cb89))
* **completion:** sort versions by latest when completing rock versions ([30c6684](https://github.com/nvim-neorocks/rocks.nvim/commit/30c66846502d186b92f921556505713a39630dd6))
* ensure that the current neovim version is neovim nightly or later ([719f97e](https://github.com/nvim-neorocks/rocks.nvim/commit/719f97e497624dae47ac73d1d939cdb164f5f3a3))
* first PoC testing version, can only install and remove (automatically) ([7afdffa](https://github.com/nvim-neorocks/rocks.nvim/commit/7afdffab0ce737b9ff4d38c27a9d7b5a8d90740e))
* make `:Rocks update` also update the `rocks.toml` file ([2536582](https://github.com/nvim-neorocks/rocks.nvim/commit/25365820ec6194d3470ca4dbc1aafa063ce5724f))
* move code to nio asynchronous logic, implement `sync` command ([30d8708](https://github.com/nvim-neorocks/rocks.nvim/commit/30d87089a89d1b5874b65b6d1119561fc09482e9))
* name and version completions for `:Rocks install` ([403d032](https://github.com/nvim-neorocks/rocks.nvim/commit/403d0325a4529c8dd780e0d9874376d2d6fb7153))
* notify the user when everything is in-sync ([9165529](https://github.com/nvim-neorocks/rocks.nvim/commit/916552939f838e3d7eaa5eaae0ee004a18d242a9))
* **operations:** add updates checker, also spotted a critical bug in the remover and documented it ([11896dd](https://github.com/nvim-neorocks/rocks.nvim/commit/11896dd86e24d46f07e30f2e2a7058f0cac305aa))
* **operations:** implement UI for `sync()` (half-buggy) ([217a8d4](https://github.com/nvim-neorocks/rocks.nvim/commit/217a8d45d0251db41234bb908c42dcca0fa3d32e))
* severely refactor internal logic, add support for updating plugins ([44d8070](https://github.com/nvim-neorocks/rocks.nvim/commit/44d8070151a6892a23bcec9b16e93bdbece4b5e3))
* UI messages for changing versions ([bff833f](https://github.com/nvim-neorocks/rocks.nvim/commit/bff833fae1d1bceae95159a1707d370742f49f74))
* vendor `nio` while it is not available on luarocks ([3f1ac14](https://github.com/nvim-neorocks/rocks.nvim/commit/3f1ac14b3bfc3d91de6f55a75f3cdb29f2f5369f))


### Bug Fixes

* `nvim_echo` may not be called in a lua loop callback ([a3b9a7c](https://github.com/nvim-neorocks/rocks.nvim/commit/a3b9a7c4ed0baba0c50e581796d06f05a4bca814))
* abort Neovim if user says no to bootstrap dependency installation ([afd3a5b](https://github.com/nvim-neorocks/rocks.nvim/commit/afd3a5b0b8714b3fc0839f1a244e914c449b250f))
* also account for `lib/` in luarocks installation path ([ba5f4bc](https://github.com/nvim-neorocks/rocks.nvim/commit/ba5f4bc460a82706d0f51a533a04464f54f37da2))
* crashes related to api-fast as well as rocks not found ([525084f](https://github.com/nvim-neorocks/rocks.nvim/commit/525084fc2e544872f9ecaeda644c535f5e2aeabc))
* **defaults:** include `nui.nvim` in the default rocks ([3980b20](https://github.com/nvim-neorocks/rocks.nvim/commit/3980b20e660ddd0e24f509b9d001140e0ccc7464))
* don't open UI on `update` if there are no updates ([06d9b60](https://github.com/nvim-neorocks/rocks.nvim/commit/06d9b60bb9202eae636a8a201cade16e317b55c8))
* improve command autocompletion ([deac73f](https://github.com/nvim-neorocks/rocks.nvim/commit/deac73fa8e34014d6baebe336dbf061a9ac98011))
* installation would fail on rocks with special characters ([e5edb77](https://github.com/nvim-neorocks/rocks.nvim/commit/e5edb770e792e6e0704ea39cb8269c140e6d72a9))
* **operations/sync:** text artifacts upon updating UI ([9848ab3](https://github.com/nvim-neorocks/rocks.nvim/commit/9848ab307da5fe69be9eff1a5202e7157baa7db4))
* **operations:** add plugin directories to rtp as soon as they get installed ([da92113](https://github.com/nvim-neorocks/rocks.nvim/commit/da921131d1381bec5be7934eaa8670defb078db9))
* plugins being installed twice, fixed UI ([45f74a9](https://github.com/nvim-neorocks/rocks.nvim/commit/45f74a999c77a335826cae5b439fee6c3e606950))
* remove accidental bootstrap_dependencies call ([#8](https://github.com/nvim-neorocks/rocks.nvim/issues/8)) ([d394c32](https://github.com/nvim-neorocks/rocks.nvim/commit/d394c325431882dd47d602f4f1295dd6ae1960ee))
* rocks with non-numerical versions would never be considered ([f884f6c](https://github.com/nvim-neorocks/rocks.nvim/commit/f884f6c5a49729774441f98ce8a54a36fffb9acf))
* **state.lua:** make the luarocks cli show dependencies with `--porcelain` ([de95dee](https://github.com/nvim-neorocks/rocks.nvim/commit/de95deed4bf6ffd24455c767f022ac66ce3d9625))
* **sync:** do not attempt to remove dependencies ([498ca1b](https://github.com/nvim-neorocks/rocks.nvim/commit/498ca1b4ee0e0b118363b3a473cf0e6b216c8e33))
* **sync:** don't mount UI if there's nothing to do ([5607c39](https://github.com/nvim-neorocks/rocks.nvim/commit/5607c398540e3643504578dbcba135ccff93693a))
* **vendor/nio:** change annotations of `nio.create` to allow return values ([ce8551e](https://github.com/nvim-neorocks/rocks.nvim/commit/ce8551e71229411c2ef3930620a44202a7583563))


### Reverts

* rename stylua.toml ([549b348](https://github.com/nvim-neorocks/rocks.nvim/commit/549b348f1326e2ee5e5f3a0ce898a90365249711))


### Code Refactoring

* start codebase refactor ([ae7aca1](https://github.com/nvim-neorocks/rocks.nvim/commit/ae7aca1a7ee31ebb544fdd06bdcc7caafc92b4f2))
