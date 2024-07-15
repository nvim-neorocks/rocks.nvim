# Changelog

## [2.35.2](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.35.1...v2.35.2) (2024-07-14)


### Bug Fixes

* **health:** fix external dependency checks ([4ae93ef](https://github.com/nvim-neorocks/rocks.nvim/commit/4ae93ef6fbc6ffa821d961d5c78a790ae0534516))
* synchronize all luarocks CLI invocations ([#474](https://github.com/nvim-neorocks/rocks.nvim/issues/474)) ([4a9c276](https://github.com/nvim-neorocks/rocks.nvim/commit/4a9c2769679a3f06b48c4e682de473e6bcecdac5))

## [2.35.1](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.35.0...v2.35.1) (2024-07-09)


### Bug Fixes

* external sync actions not running ([#469](https://github.com/nvim-neorocks/rocks.nvim/issues/469)) ([235c7df](https://github.com/nvim-neorocks/rocks.nvim/commit/235c7df46ff5e54d89ba46e2beb6c3656b6d49d6))
* **install:** add newly installed `opt` plugins to the rtp ([54a5cfd](https://github.com/nvim-neorocks/rocks.nvim/commit/54a5cfd5bf6a8aea733d07c28beeaf2bd080ab35))

## [2.35.0](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.34.0...v2.35.0) (2024-07-05)


### Features

* **install:** add breaking change check for `Rocks install {rock}` ([91431b4](https://github.com/nvim-neorocks/rocks.nvim/commit/91431b4bc46fc1bafbccc4d00dd91fb6337b8255))
* **install:** skip prompts with `Rocks! install` ([46f154a](https://github.com/nvim-neorocks/rocks.nvim/commit/46f154ac18afeb8b87d12487dd2dc53688aa6fc8))
* support extending the default luarocks config with a table ([00014a8](https://github.com/nvim-neorocks/rocks.nvim/commit/00014a89a81d7f083367ce8769dc67153f0e8bd6))
* **update:** prompt to install breaking changes ([6be3fe5](https://github.com/nvim-neorocks/rocks.nvim/commit/6be3fe5851a0c59dc3a092fec2b1d077a7a4f2d5))

## [2.34.0](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.33.0...v2.34.0) (2024-07-03)


### Features

* **install:** Error if trying to install lua rocks by owner/repo ([#445](https://github.com/nvim-neorocks/rocks.nvim/issues/445)) ([36041f2](https://github.com/nvim-neorocks/rocks.nvim/commit/36041f2788f6eea7a29b154e4fbe8f1149c81758))
* **log:** trace luarocks_config path ([#450](https://github.com/nvim-neorocks/rocks.nvim/issues/450)) ([c3b0297](https://github.com/nvim-neorocks/rocks.nvim/commit/c3b0297bc48eb8d1d046c586fd5195786b8b10d7))
* **rocks.toml:** support specifying extra luarocks `install_args` ([#442](https://github.com/nvim-neorocks/rocks.nvim/issues/442)) ([ca44f7b](https://github.com/nvim-neorocks/rocks.nvim/commit/ca44f7bcd879c7e4538a02184b1f922d549cde41))

## [2.33.0](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.32.1...v2.33.0) (2024-07-02)


### Features

* **health:** check for nvim-treesitter conflicts ([#447](https://github.com/nvim-neorocks/rocks.nvim/issues/447)) ([170a1b0](https://github.com/nvim-neorocks/rocks.nvim/commit/170a1b071e1c1dd8dc3446ace6bcacab466c355d))
* **install:** improve 'dev' version search prompt ([#446](https://github.com/nvim-neorocks/rocks.nvim/issues/446)) ([7b454ba](https://github.com/nvim-neorocks/rocks.nvim/commit/7b454baeaa1695b6e8334ea8872a39c668e26f88))


### Bug Fixes

* **prune:** need to prune twice for rocks-git to remove plugin ([#451](https://github.com/nvim-neorocks/rocks.nvim/issues/451)) ([f8edb17](https://github.com/nvim-neorocks/rocks.nvim/commit/f8edb1744ee895daee31617f710224e1f7b15913))

## [2.32.1](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.32.0...v2.32.1) (2024-06-29)


### Bug Fixes

* **api:** use user rocks with preload hook modifications applied ([#436](https://github.com/nvim-neorocks/rocks.nvim/issues/436)) ([4fb7896](https://github.com/nvim-neorocks/rocks.nvim/commit/4fb7896edc1273dfca36828f5b8200363c6e0c69))
* **health:** do not produce duplicated messages when there are no errors in the `rocks.toml` file ([cf2fdee](https://github.com/nvim-neorocks/rocks.nvim/commit/cf2fdee9f2c22513752b0cf1bc7a6da417a3ce2b))

## [2.32.0](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.31.3...v2.32.0) (2024-06-25)


### Features

* **api:** `RockSpecModifier` preload hooks ([#392](https://github.com/nvim-neorocks/rocks.nvim/issues/392)) ([04d63e2](https://github.com/nvim-neorocks/rocks.nvim/commit/04d63e204923daa301292f8012b553f875c17dc9))


### Bug Fixes

* **prune:** delegate to extensions' handlers ([#400](https://github.com/nvim-neorocks/rocks.nvim/issues/400)) ([5a01433](https://github.com/nvim-neorocks/rocks.nvim/commit/5a0143366432fd2151fa0476be796432446e604f))

## [2.31.3](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.31.2...v2.31.3) (2024-06-19)


### Bug Fixes

* **update:** set version of all installed rocks.toml entries ([#382](https://github.com/nvim-neorocks/rocks.nvim/issues/382)) ([56460c8](https://github.com/nvim-neorocks/rocks.nvim/commit/56460c8183e6f471ac1bf7ce8bf0fa1e02344421))

## [2.31.2](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.31.1...v2.31.2) (2024-06-19)


### Bug Fixes

* **runtime:** make sure dependencies' rtp directories can be used ([#394](https://github.com/nvim-neorocks/rocks.nvim/issues/394)) ([eba13e0](https://github.com/nvim-neorocks/rocks.nvim/commit/eba13e0cdb57352e8df0fb8c5c71f9a0aed00e8b))

## [2.31.1](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.31.0...v2.31.1) (2024-06-17)


### Bug Fixes

* **api:** include `dev` rocks in `query_luarocks_rocks` ([#389](https://github.com/nvim-neorocks/rocks.nvim/issues/389)) ([06ea5e1](https://github.com/nvim-neorocks/rocks.nvim/commit/06ea5e1e36baa52590a03bdef91f7f893415a884))

## [2.31.0](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.30.1...v2.31.0) (2024-06-11)


### Features

* **config:** add validation that luarocks binary is executable ([09c93f1](https://github.com/nvim-neorocks/rocks.nvim/commit/09c93f1b235dc07de18e63a5392bde17dddc29dd))


### Bug Fixes

* fail silently if populating the rocks cache fails at startup ([3fb4a06](https://github.com/nvim-neorocks/rocks.nvim/commit/3fb4a06b286bbcf020de843ce8e2c74d24195585))
* luarocks.core.cfg not found when removing bootstrapped luarocks ([483c61a](https://github.com/nvim-neorocks/rocks.nvim/commit/483c61ade8c93c12e36cd93f712b0b56b90da3ed))

## [2.30.1](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.30.0...v2.30.1) (2024-06-10)


### Bug Fixes

* **luarocks:** set `LUA_PATH` and `LUA_CPATH` ([#374](https://github.com/nvim-neorocks/rocks.nvim/issues/374)) ([a7de46b](https://github.com/nvim-neorocks/rocks.nvim/commit/a7de46bb93cc4b982629460544fc9b2c3c64a167))

## [2.30.0](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.29.2...v2.30.0) (2024-06-07)


### Features

* manage luarocks installation as rockspec dependency ([#340](https://github.com/nvim-neorocks/rocks.nvim/issues/340)) ([b74b36f](https://github.com/nvim-neorocks/rocks.nvim/commit/b74b36f0dc0653d19bd01a0162420397ed170feb))

## [2.29.2](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.29.1...v2.29.2) (2024-05-30)


### Bug Fixes

* **sync/ui:** progess ui displayed forever ([#360](https://github.com/nvim-neorocks/rocks.nvim/issues/360)) ([629b37b](https://github.com/nvim-neorocks/rocks.nvim/commit/629b37b4e115eb502a18e2ced691e3f7340d4c51))

## [2.29.1](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.29.0...v2.29.1) (2024-05-27)


### Bug Fixes

* **operations:** always force reinstalls if rocks are already installed ([#353](https://github.com/nvim-neorocks/rocks.nvim/issues/353)) ([8537f6a](https://github.com/nvim-neorocks/rocks.nvim/commit/8537f6a69213b42daaf2a5d25c8df38ee8bd41af))
* **tree-sitter:** stop creating now redundant `rocks_rtp/parser` symlink ([4e4ab38](https://github.com/nvim-neorocks/rocks.nvim/commit/4e4ab380bdb910896dd00c7307d28f4cb3db99b7))

## [2.29.0](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.28.0...v2.29.0) (2024-05-21)


### Features

* allow overriding luarocks config ([#334](https://github.com/nvim-neorocks/rocks.nvim/issues/334)) ([02f77e8](https://github.com/nvim-neorocks/rocks.nvim/commit/02f77e8a56ded3fa4ae97c83530d97c0d3bb78ba))
* **log:** include error messages reported in UI ([#322](https://github.com/nvim-neorocks/rocks.nvim/issues/322)) ([0a85746](https://github.com/nvim-neorocks/rocks.nvim/commit/0a85746f097e900ad39ca17e43fdb2c19dca1958))


### Bug Fixes

* **operations:** race conditions when running commands concurrently ([269bbf3](https://github.com/nvim-neorocks/rocks.nvim/commit/269bbf3dab19a9780e4fc920ae7b766ffa9c9ecc))
* **sync:** prune all rocks that can be pruned in a single sweep ([#305](https://github.com/nvim-neorocks/rocks.nvim/issues/305)) ([e6c2080](https://github.com/nvim-neorocks/rocks.nvim/commit/e6c2080a515c5a74b3e4b6a03bcee8f6f1d603f6))
* wait for writing rocks.toml to complete where possible ([37924fa](https://github.com/nvim-neorocks/rocks.nvim/commit/37924faf5df65514cb9aaf3a08c8025e3ee05220))


### Performance Improvements

* replace `vim.g` with `_G` in init check ([509e872](https://github.com/nvim-neorocks/rocks.nvim/commit/509e8720264426c6b18c0e21ca67aaaee0d2e5bc))


### Reverts

* replace `vim.g` with `_G` in init check ([27912ea](https://github.com/nvim-neorocks/rocks.nvim/commit/27912ea001b6cb69d20eaf4db763d670fa228b8d))

## [2.28.0](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.27.1...v2.28.0) (2024-05-16)


### Features

* replace nightly requirement with Neovim &gt;= 0.10.0 ([db09871](https://github.com/nvim-neorocks/rocks.nvim/commit/db098713801a4d41d047618f4e4662e85e1dd4bf))

## [2.27.1](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.27.0...v2.27.1) (2024-05-06)


### Bug Fixes

* **operations:** error if 'rocks' or 'plugin' key missing in rocks.toml ([#318](https://github.com/nvim-neorocks/rocks.nvim/issues/318)) ([45570ab](https://github.com/nvim-neorocks/rocks.nvim/commit/45570abb2c1b605042e3a0cabc428e72167b59df))

## [2.27.0](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.26.0...v2.27.0) (2024-05-06)


### Features

* set log level to WARN ([71446ce](https://github.com/nvim-neorocks/rocks.nvim/commit/71446ce2988445216c6c1368c7f91123830c8839))
* show "Run ':Rocks log' for details" tip when error occurs ([f345607](https://github.com/nvim-neorocks/rocks.nvim/commit/f345607d6daefd05f15b59e00b4f18c45f8a92a3))


### Bug Fixes

* **luarocks:** add `--force-lock` flag ([#306](https://github.com/nvim-neorocks/rocks.nvim/issues/306)) ([f37f42b](https://github.com/nvim-neorocks/rocks.nvim/commit/f37f42b954585181941f2c3715aa88bfa77f0dcd))

## [2.26.0](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.25.1...v2.26.0) (2024-04-25)


### Features

* deprecate `rocks.api.source_runtime_dir` ([#297](https://github.com/nvim-neorocks/rocks.nvim/issues/297)) ([b93c313](https://github.com/nvim-neorocks/rocks.nvim/commit/b93c3137bf1b5e32e14ab7c2ea45fcf48e8024db))
* **runtime:** use built-in `packadd` and deprecate `Rocks packadd` ([047b8f7](https://github.com/nvim-neorocks/rocks.nvim/commit/047b8f7079188a6b7e17817b9cfa0dcc09b94dcc))

## [2.25.1](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.25.0...v2.25.1) (2024-04-24)


### Bug Fixes

* **sync:** error when rocks.toml has no rocks or plugins entries ([#295](https://github.com/nvim-neorocks/rocks.nvim/issues/295)) ([e74ffdd](https://github.com/nvim-neorocks/rocks.nvim/commit/e74ffdd49b7f8758ca282e812daf00fc774b9439))

## [2.25.0](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.24.0...v2.25.0) (2024-04-24)


### Features

* ensure plugin runtime paths are available before rocks initialises ([#285](https://github.com/nvim-neorocks/rocks.nvim/issues/285)) ([462379d](https://github.com/nvim-neorocks/rocks.nvim/commit/462379ddb8021b558dcceb1c3f005516140a2650))


### Bug Fixes

* ensure lowercase rock names ([#288](https://github.com/nvim-neorocks/rocks.nvim/issues/288)) ([4d4b0a7](https://github.com/nvim-neorocks/rocks.nvim/commit/4d4b0a729743b594050a24f6f3e3053045564da3))
* **update:** don't update rocks that aren't in rocks.toml ([c969b61](https://github.com/nvim-neorocks/rocks.nvim/commit/c969b611ed4bd45ee5c0788a96c8d7b1bf40a421))

## [2.24.0](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.23.0...v2.24.0) (2024-04-18)


### Features

* add bootstrap.lua script ([e25027e](https://github.com/nvim-neorocks/rocks.nvim/commit/e25027e8b082eb9730f39f1daed930cb476647cb))
* add rest of installer code ([8508e5a](https://github.com/nvim-neorocks/rocks.nvim/commit/8508e5ad66051ddb8d364574bc8c26faccc081eb))
* initial bootstrap.lua script ([cd213f4](https://github.com/nvim-neorocks/rocks.nvim/commit/cd213f413761b186b83f946eb68806d95d9df9fd))


### Bug Fixes

* access rocks_nvim instead of rocks_config ([4fd4599](https://github.com/nvim-neorocks/rocks.nvim/commit/4fd4599bf027b87568e01af0b0b04c9f4a087a93))
* broken/cut-off README ([4acbe96](https://github.com/nvim-neorocks/rocks.nvim/commit/4acbe96e4980dd836afa6c401924b96aab0a5b35))
* duplicate variable names, proper fallback for `luarocks_binary` ([e92c768](https://github.com/nvim-neorocks/rocks.nvim/commit/e92c7687174f305d7ad06cf9b332384469b1df6a))
* set random seed to system time for reproducible clones ([c4fadfb](https://github.com/nvim-neorocks/rocks.nvim/commit/c4fadfb63e71cd88dff9269bc85ba292cf2168dc))

## [2.23.0](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.22.0...v2.23.0) (2024-04-18)


### Features

* `Rocks [pin|unpin] {rock}` command ([#280](https://github.com/nvim-neorocks/rocks.nvim/issues/280)) ([210bf6a](https://github.com/nvim-neorocks/rocks.nvim/commit/210bf6a73bbef87bfed8cfa00f491b8befadbe56))

## [2.22.0](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.21.3...v2.22.0) (2024-04-17)


### Features

* add version check to installer and plugin script ([#277](https://github.com/nvim-neorocks/rocks.nvim/issues/277)) ([c54d6e2](https://github.com/nvim-neorocks/rocks.nvim/commit/c54d6e2fff0e387874a804dc08b754bf9234d6a8))
* pin rocks to prevent updates ([#278](https://github.com/nvim-neorocks/rocks.nvim/issues/278)) ([832c400](https://github.com/nvim-neorocks/rocks.nvim/commit/832c4003b8238d67061d11d0c774b884dfdbdd34))

## [2.21.3](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.21.2...v2.21.3) (2024-04-13)


### Bug Fixes

* **installer:** update `package.cpath` for all platforms ([#271](https://github.com/nvim-neorocks/rocks.nvim/issues/271)) ([9cc0203](https://github.com/nvim-neorocks/rocks.nvim/commit/9cc0203571dfe8e8b63bbed0a68ef9b2f5ed8ba0))

## [2.21.2](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.21.1...v2.21.2) (2024-04-13)


### Bug Fixes

* **runtime:** append start plugins to rtp before calling preload hooks ([#267](https://github.com/nvim-neorocks/rocks.nvim/issues/267)) ([f86ffe6](https://github.com/nvim-neorocks/rocks.nvim/commit/f86ffe65e4617a48c0c3da9efa92fdac998d44eb))

## [2.21.1](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.21.0...v2.21.1) (2024-04-09)


### Bug Fixes

* **loader:** only enable luarocks loader for luarocks with lua 5.1 ([772e828](https://github.com/nvim-neorocks/rocks.nvim/commit/772e8289e76750847d8732ddcc63f12a0de28c5f))

## [2.21.0](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.20.2...v2.21.0) (2024-04-07)


### Features

* keep log file in rocks_path ([8b5e584](https://github.com/nvim-neorocks/rocks.nvim/commit/8b5e5849f3ff49c7707fd5b1bd5e3836967b13ab))

## [2.20.2](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.20.1...v2.20.2) (2024-04-07)


### Bug Fixes

* **dependencies:** bump toml-edit to a working version ([#251](https://github.com/nvim-neorocks/rocks.nvim/issues/251)) ([8ca5cfe](https://github.com/nvim-neorocks/rocks.nvim/commit/8ca5cfe8f4415ffe9a27b021fb48fd67fc3e57b3))

## [2.20.1](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.20.0...v2.20.1) (2024-04-07)


### Bug Fixes

* **loader:** add entire luarocks lua path ([#248](https://github.com/nvim-neorocks/rocks.nvim/issues/248)) ([0d041ec](https://github.com/nvim-neorocks/rocks.nvim/commit/0d041ecb255b13480fa921214a29f7aecb210331))

## [2.20.0](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.19.1...v2.20.0) (2024-04-03)


### Features

* **install:** support passing args, like `opt=true` ([#236](https://github.com/nvim-neorocks/rocks.nvim/issues/236)) ([f4d25d9](https://github.com/nvim-neorocks/rocks.nvim/commit/f4d25d933b95268cedaa18a1e19f781054ed0027))
* **loader:** support multiple versions of the same dependency ([#227](https://github.com/nvim-neorocks/rocks.nvim/issues/227)) ([cb2be55](https://github.com/nvim-neorocks/rocks.nvim/commit/cb2be55ccb50badef39ac2ba0fbf0d22a7ae51f1))

## [2.19.1](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.19.0...v2.19.1) (2024-03-24)


### Bug Fixes

* **completions:** don't exclude dev versions in luarocks search ([1c56f32](https://github.com/nvim-neorocks/rocks.nvim/commit/1c56f323da8e8bed936006cb87cacc712237993a))

## [2.19.0](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.18.0...v2.19.0) (2024-03-23)


### Features

* **api:** `install` function for installing rocks with a callback ([#217](https://github.com/nvim-neorocks/rocks.nvim/issues/217)) ([0df5915](https://github.com/nvim-neorocks/rocks.nvim/commit/0df5915c28d8871e41cf833f5b50176951518e2b))

## [2.18.0](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.17.0...v2.18.0) (2024-03-21)


### Features

* **lua-api:** add `rocks.packadd` function ([#214](https://github.com/nvim-neorocks/rocks.nvim/issues/214)) ([ad6cd44](https://github.com/nvim-neorocks/rocks.nvim/commit/ad6cd4483b55c8ac2cfb48c7d6509561febee87c))

## [2.17.0](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.16.0...v2.17.0) (2024-03-20)


### Features

* **api:** introduce `preload` hooks for rocks.nvim extensions ([#209](https://github.com/nvim-neorocks/rocks.nvim/issues/209)) ([ebaf92e](https://github.com/nvim-neorocks/rocks.nvim/commit/ebaf92ed160b68a018e1bf772fb5027578149bb9))
* search rocks-binaries-dev server if version is dev or scm ([#197](https://github.com/nvim-neorocks/rocks.nvim/issues/197)) ([11fe71a](https://github.com/nvim-neorocks/rocks.nvim/commit/11fe71a6593fa0fee29db313650cc3fae0570747))
* **sync:** bootstrap external sync handlers and use them in one sync sweep ([#211](https://github.com/nvim-neorocks/rocks.nvim/issues/211)) ([d6e9bda](https://github.com/nvim-neorocks/rocks.nvim/commit/d6e9bdaccf3339d687b7a3a03ddd351a469fbae4))
* **update:** reinstall `dev` rocks by default ([#210](https://github.com/nvim-neorocks/rocks.nvim/issues/210)) ([de1c86c](https://github.com/nvim-neorocks/rocks.nvim/commit/de1c86c93fb671c695f13cbba0b4ee35677e81e7))


### Bug Fixes

* async initialise + cleanup tree-sitter parser symlink ([#202](https://github.com/nvim-neorocks/rocks.nvim/issues/202)) ([621337c](https://github.com/nvim-neorocks/rocks.nvim/commit/621337c4b7346532b6c5bc957aba2b239599544e))
* **installer:** missing comma ([#206](https://github.com/nvim-neorocks/rocks.nvim/issues/206)) ([fb195f1](https://github.com/nvim-neorocks/rocks.nvim/commit/fb195f1ff7e1ef576824d94c18359727a2fa7f5e))
* **installer:** Respect shell shebang of luarocks configure script ([#200](https://github.com/nvim-neorocks/rocks.nvim/issues/200)) ([eaac7b1](https://github.com/nvim-neorocks/rocks.nvim/commit/eaac7b11c4730f5d74d4e5cb217ac3e5e860330d))
* remove unnecessary guards ([#201](https://github.com/nvim-neorocks/rocks.nvim/issues/201)) ([e3b2e0d](https://github.com/nvim-neorocks/rocks.nvim/commit/e3b2e0d8df7a4e57c62478399ab90ca77301a658))
* **sync:** error when version in rocks.toml is `scm` or `dev` ([#193](https://github.com/nvim-neorocks/rocks.nvim/issues/193)) ([5244346](https://github.com/nvim-neorocks/rocks.nvim/commit/5244346aed53834bf7d3f6dbd0ad50501036de49))


### Reverts

* set LUAROCKS_CONFIG to `nil`, not an empty string ([821f5fe](https://github.com/nvim-neorocks/rocks.nvim/commit/821f5fe15326bf9120a0e590dd63404e7481c4f6))

## [2.16.0](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.15.0...v2.16.0) (2024-03-15)


### Features

* **install:** prompt to search dev version if rock not found ([#191](https://github.com/nvim-neorocks/rocks.nvim/issues/191)) ([66d6e8a](https://github.com/nvim-neorocks/rocks.nvim/commit/66d6e8ad1a7e616f73ed34a435b77ee968effa2f))


### Bug Fixes

* **install:** add `--dev` flag if version is `scm` ([69921f1](https://github.com/nvim-neorocks/rocks.nvim/commit/69921f1e82283965f687f417378b753436f26745))

## [2.15.0](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.14.0...v2.15.0) (2024-03-13)


### Features

* add support for tree-sitter parsers installed from luarocks ([141e5f8](https://github.com/nvim-neorocks/rocks.nvim/commit/141e5f8044435fc191874cac7f6923a22c78e5fb))
* **treesitter:** set `TREE_SITTER_LANGUAGE_VERSION` ([34996d8](https://github.com/nvim-neorocks/rocks.nvim/commit/34996d83d936fd2c32e7f341fdeb13e87593f0f4))


### Bug Fixes

* **install:** don't `packadd` if installed rockspec is `opt` ([217ef32](https://github.com/nvim-neorocks/rocks.nvim/commit/217ef32876c0298eaf46d95c1d845ce545e0b4e8))
* **installer:** proper C lib file extension on darwin and windows ([#186](https://github.com/nvim-neorocks/rocks.nvim/issues/186)) ([855d556](https://github.com/nvim-neorocks/rocks.nvim/commit/855d5563c878047c02205065afff36a1959163a4))
* **operations:** ensure luarocks prioritizes rocks-binaries ([de3cbb6](https://github.com/nvim-neorocks/rocks.nvim/commit/de3cbb642d81d2185fca93c55ede9f4b9c5a104e))

## [2.14.0](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.13.1...v2.14.0) (2024-03-09)


### Features

* **completions:** include dev versions in luarocks search ([98ae8fc](https://github.com/nvim-neorocks/rocks.nvim/commit/98ae8fcb4a19e985561b75ea37a91806de328b78))


### Bug Fixes

* **installer:** use `vim.o.sh` instead of `'sh'` ([#179](https://github.com/nvim-neorocks/rocks.nvim/issues/179)) ([54b67ce](https://github.com/nvim-neorocks/rocks.nvim/commit/54b67cec53f4152c85fb8f7b77a939514b5f78a5))


### Performance Improvements

* **installer:** Use `--filter=blob:none` when cloning luarocks ([919541e](https://github.com/nvim-neorocks/rocks.nvim/commit/919541e564f80a288a5fe3587963cdf4f4e6b099))


### Reverts

* **installer:** stay on old luarocks commit ([#180](https://github.com/nvim-neorocks/rocks.nvim/issues/180)) ([6c0403a](https://github.com/nvim-neorocks/rocks.nvim/commit/6c0403a3fff682a0c1266b62567eca4ce5f2f139))

## [2.13.1](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.13.0...v2.13.1) (2024-03-02)


### Bug Fixes

* invocation of invalid rtp sourcing function ([073d8e5](https://github.com/nvim-neorocks/rocks.nvim/commit/073d8e588d9f6776cb661d513a3d1f5149f928c6))

## [2.13.0](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.12.1...v2.13.0) (2024-03-02)


### Features

* use the neorocks manifest as a fallback server ([7e9cf5d](https://github.com/nvim-neorocks/rocks.nvim/commit/7e9cf5d9128708447ed8e478533520272a51ca2f))


### Bug Fixes

* ignore malformed rocks ([5407b73](https://github.com/nvim-neorocks/rocks.nvim/commit/5407b736d1214a09d99f9cbc0c71fbab14fd3a22))

## [2.12.1](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.12.0...v2.12.1) (2024-02-29)


### Bug Fixes

* check that handler callbacks are set before trying to call them ([02a2749](https://github.com/nvim-neorocks/rocks.nvim/commit/02a2749fce07b0c52c28c3a5b03d1fc89a15dcba))

## [2.12.0](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.11.0...v2.12.0) (2024-02-28)


### Features

* **api:** ability to hook into `:Rocks install` and `:Rocks update` ([#165](https://github.com/nvim-neorocks/rocks.nvim/issues/165)) ([7f6e26f](https://github.com/nvim-neorocks/rocks.nvim/commit/7f6e26f66ab68fa46ae99514d2a6f59708c289ad))

## [2.11.0](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.10.0...v2.11.0) (2024-02-23)


### Features

* add support for `:checkhealth` ([5b77337](https://github.com/nvim-neorocks/rocks.nvim/commit/5b7733755d3208465f226c3ff51dd69703379015))

## [2.10.0](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.9.0...v2.10.0) (2024-02-23)


### Features

* **api:** add `source_runtime_dir` ([c47327b](https://github.com/nvim-neorocks/rocks.nvim/commit/c47327bf5a8d2554b4f3f9100f94d6e5be3d15c8))

## [2.9.0](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.8.2...v2.9.0) (2024-02-17)


### Features

* add luarocks `bin` directory to the Neovim path ([#153](https://github.com/nvim-neorocks/rocks.nvim/issues/153)) ([13c2103](https://github.com/nvim-neorocks/rocks.nvim/commit/13c2103d580920367c4c7e63cb321befafcf36c4))

## [2.8.2](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.8.1...v2.8.2) (2024-02-16)


### Bug Fixes

* **luarocks:** make sure `LUAROCKS_CONFIG` is unset ([#150](https://github.com/nvim-neorocks/rocks.nvim/issues/150)) ([8cfb41b](https://github.com/nvim-neorocks/rocks.nvim/commit/8cfb41bb73a7f4f013810a1ae0da8dd5f54fd90c))

## [2.8.1](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.8.0...v2.8.1) (2024-02-16)


### Bug Fixes

* **config:** create default config on `:Rocks edit` if it does not exist ([7b35d9a](https://github.com/nvim-neorocks/rocks.nvim/commit/7b35d9a718b22be53770f42f3276fb619f2746c1))
* **config:** create directory before creating default config ([5446cd4](https://github.com/nvim-neorocks/rocks.nvim/commit/5446cd41ba1f7aac096e680620ec3e63a281ee0b))

## [2.8.0](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.7.4...v2.8.0) (2024-02-12)


### Features

* generate plugins help pages tags on install/update ([#145](https://github.com/nvim-neorocks/rocks.nvim/issues/145)) ([ab1f8c6](https://github.com/nvim-neorocks/rocks.nvim/commit/ab1f8c61286029344c82de0cc8a1c1b9ab957aec))

## [2.7.4](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.7.3...v2.7.4) (2024-02-11)


### Bug Fixes

* **update:** dependencies added to rocks.toml after updating ([#143](https://github.com/nvim-neorocks/rocks.nvim/issues/143)) ([7e650f2](https://github.com/nvim-neorocks/rocks.nvim/commit/7e650f20f9ad840d5499fd8f4076604e12465d0a))

## [2.7.3](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.7.2...v2.7.3) (2024-02-01)


### Bug Fixes

* **installer:** remove color seqence from shell output ([#130](https://github.com/nvim-neorocks/rocks.nvim/issues/130)) ([6c6da2b](https://github.com/nvim-neorocks/rocks.nvim/commit/6c6da2b3690e87283fb584f32a18c7f1a5246a3f))

## [2.7.2](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.7.1...v2.7.2) (2024-01-27)


### Bug Fixes

* **installer:** disable line wrapping for option's windows ([#125](https://github.com/nvim-neorocks/rocks.nvim/issues/125)) ([298e10a](https://github.com/nvim-neorocks/rocks.nvim/commit/298e10aba4b81b3ddd624d34aa60669261a243c2))
* **installer:** don't fail if pinning luarocks revision fails ([474a7ca](https://github.com/nvim-neorocks/rocks.nvim/commit/474a7ca5822cbe9b41537914c73b37781bb1833d))
* **installer:** prevent invalid temp directory name generation ([#118](https://github.com/nvim-neorocks/rocks.nvim/issues/118)) ([14578d0](https://github.com/nvim-neorocks/rocks.nvim/commit/14578d07bc64e45c369ca6d841855174ae243075))
* **installer:** print `stderr` + `stdout` on failure ([1c5efc9](https://github.com/nvim-neorocks/rocks.nvim/commit/1c5efc98121491455d9fd337b8ce80d6c2a53595))
* **runtime:** only show `packadd` fallback error if configured to do so ([#128](https://github.com/nvim-neorocks/rocks.nvim/issues/128)) ([9682c0c](https://github.com/nvim-neorocks/rocks.nvim/commit/9682c0c9ed66487df887bbe4ea3248058eac036e))

## [2.7.1](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.7.0...v2.7.1) (2024-01-25)


### Bug Fixes

* don't show "Updated rock" notification on failed update ([996c0c6](https://github.com/nvim-neorocks/rocks.nvim/commit/996c0c673218eb633580a413364a81eb3c7dccfd))


### Reverts

* better stack traces ([#104](https://github.com/nvim-neorocks/rocks.nvim/issues/104)) ([d4d057c](https://github.com/nvim-neorocks/rocks.nvim/commit/d4d057c36e01096c3fe0e674c932978035243a0e))

## [2.7.0](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.6.2...v2.7.0) (2024-01-14)


### Features

* **packadd:** Fall back to builtin `packadd` if no rock is found. ([#114](https://github.com/nvim-neorocks/rocks.nvim/issues/114)) ([816b916](https://github.com/nvim-neorocks/rocks.nvim/commit/816b9164f234a34445ee89374b719b35540ee225))

## [2.6.2](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.6.1...v2.6.2) (2024-01-14)


### Bug Fixes

* better stack traces ([#104](https://github.com/nvim-neorocks/rocks.nvim/issues/104)) ([af1d92f](https://github.com/nvim-neorocks/rocks.nvim/commit/af1d92f5a5f2b27f429df76298743ac4741ed4f2))
* **runtime:** variable naming conflict ([#112](https://github.com/nvim-neorocks/rocks.nvim/issues/112)) ([e3294ee](https://github.com/nvim-neorocks/rocks.nvim/commit/e3294eeef1f148ed3f3c937c330ab234ddf9a387))

## [2.6.1](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.6.0...v2.6.1) (2023-12-31)


### Bug Fixes

* **api:** ensure `get_rocks_toml` returns `RockSpec[]` tables ([dcfd23c](https://github.com/nvim-neorocks/rocks.nvim/commit/dcfd23c3bad72c82e2904312a3060892ef4b29ae))
* **sync:** error when downgrading from `scm`/`dev` versions ([afee345](https://github.com/nvim-neorocks/rocks.nvim/commit/afee34525629d9cc160be0c4cba70b2c15666bcf))
* **update,install:** rocks.toml entries coerced to strings ([ef8d8af](https://github.com/nvim-neorocks/rocks.nvim/commit/ef8d8afe8e0b13cbbea437ca546b04bf95657da1))

## [2.6.0](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.5.0...v2.6.0) (2023-12-26)


### Features

* `:Rocks packadd` commmand for lazy-loading `opt` plugins ([#99](https://github.com/nvim-neorocks/rocks.nvim/issues/99)) ([89fa2b8](https://github.com/nvim-neorocks/rocks.nvim/commit/89fa2b800036bef4a32414b2ff28c9f373ce71ec))

## [2.5.0](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.4.1...v2.5.0) (2023-12-21)


### Features

* **deps:** replace internal `nio` module with `nvim-nio` ([b10889e](https://github.com/nvim-neorocks/rocks.nvim/commit/b10889e64a81092639628d1980273c33081eea44))


### Bug Fixes

* **installer:** stay on old luarocks commit, fix `/run/.../luarocks already exists` error ([57e80f7](https://github.com/nvim-neorocks/rocks.nvim/commit/57e80f7f5ecdc55e51554024e975102a8f86c86b))

## [2.4.1](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.4.0...v2.4.1) (2023-12-17)


### Bug Fixes

* **sync:** Better error message if entry can't be parsed ([#90](https://github.com/nvim-neorocks/rocks.nvim/issues/90)) ([2f844ff](https://github.com/nvim-neorocks/rocks.nvim/commit/2f844ff4a72c4318672d1f31ba9f3ea76db4db50))


### Reverts

* **installer:** only add rocks.nvim to rtp in install script ([#88](https://github.com/nvim-neorocks/rocks.nvim/issues/88)) ([#91](https://github.com/nvim-neorocks/rocks.nvim/issues/91)) ([1c16e6b](https://github.com/nvim-neorocks/rocks.nvim/commit/1c16e6bfd15970704979be2c07f6e041d4c4af7a))

## [2.4.0](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.3.3...v2.4.0) (2023-12-17)


### Features

* add `dynamic_rtp` option ([609cc53](https://github.com/nvim-neorocks/rocks.nvim/commit/609cc530991ab6b3a402656c80da521c3ee3e298))
* **api:** allow external modules to hook into `:Rocks sync` ([#85](https://github.com/nvim-neorocks/rocks.nvim/issues/85)) ([9b66e52](https://github.com/nvim-neorocks/rocks.nvim/commit/9b66e52533fb314c8b312e49c6152599bdc84408))
* auto add newly installed plugins to the RTP ([5ea1004](https://github.com/nvim-neorocks/rocks.nvim/commit/5ea1004c6510ef05ec528ac2e3a190b15220bacc))

## [2.3.3](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.3.2...v2.3.3) (2023-12-12)


### Bug Fixes

* **operations/update:** display "Checking for updates..." message before performing update checks ([#73](https://github.com/nvim-neorocks/rocks.nvim/issues/73)) ([d01b1e6](https://github.com/nvim-neorocks/rocks.nvim/commit/d01b1e6f14de5c070e68a4842b54886fe4f5f3e5))
* **update:** exclude `-&lt;specrev&gt;` from version ([b7e096b](https://github.com/nvim-neorocks/rocks.nvim/commit/b7e096bb2d043f5b274674f859754f74348895e6))

## [2.3.2](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.3.1...v2.3.2) (2023-12-11)


### Bug Fixes

* **install:** ensure lower case rock names ([1f1d0a4](https://github.com/nvim-neorocks/rocks.nvim/commit/1f1d0a4672e3644b4f0da82fedfddbc0dd77433a))

## [2.3.1](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.3.0...v2.3.1) (2023-12-11)


### Bug Fixes

* **config:** remove unimplemented example from default config ([3897048](https://github.com/nvim-neorocks/rocks.nvim/commit/38970480247a5ca9e95a13b29716236a8d58ff6c))
* **ui:** limit progress percentages to [0,100] ([a18fb7d](https://github.com/nvim-neorocks/rocks.nvim/commit/a18fb7d9a4a054d200533eae64c3491fcc79942e))
* **update:** update versions in `rocks.toml` ([675bda0](https://github.com/nvim-neorocks/rocks.nvim/commit/675bda05d8326ab5fe43194fd1db907197c541c1))

## [2.3.0](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.2.0...v2.3.0) (2023-12-11)


### Features

* logging + `:Rocks log` command ([#65](https://github.com/nvim-neorocks/rocks.nvim/issues/65)) ([4a0678d](https://github.com/nvim-neorocks/rocks.nvim/commit/4a0678d31fb3aa5793cb2aa30eaa5c0f8a6f0511))
* **sync:** separate progress handles for errors ([a08ee0d](https://github.com/nvim-neorocks/rocks.nvim/commit/a08ee0d0f9491ca1ae29d9fdff05a696bfd55640))


### Bug Fixes

* **install:** bug causing `:` to be appended to version in rocks.toml ([#62](https://github.com/nvim-neorocks/rocks.nvim/issues/62)) ([8e8ceec](https://github.com/nvim-neorocks/rocks.nvim/commit/8e8ceecba81d528b39e696d85e44ca3364af8341))
* **operations:** don't use parse_user_rocks in sync ([e82f66f](https://github.com/nvim-neorocks/rocks.nvim/commit/e82f66f696b41cfafe0e3a27ed2dea3e94e9b5db))
* **prune:** do not prune dependencies that are in `rocks.toml` ([8a48a1a](https://github.com/nvim-neorocks/rocks.nvim/commit/8a48a1aad30f5651287cc0ab7e7d34a9722ca247))
* **prune:** remove pruned rocks from [rocks] section, too ([9857745](https://github.com/nvim-neorocks/rocks.nvim/commit/98577458f87f404265ecef6ab07b55533c395bee))
* **sync:** don't try to remove indirect dependencies ([a1c0d2f](https://github.com/nvim-neorocks/rocks.nvim/commit/a1c0d2fbd0e531160876348d4ecbc9a3583a0ffe))
* **sync:** prevent luarocks race conditions ([057ec56](https://github.com/nvim-neorocks/rocks.nvim/commit/057ec5653d4ab9c3bb31316d40a3e7f2a03e4aff))
* **sync:** prune rocks sequentially to prevent partial uninstalls ([d09de43](https://github.com/nvim-neorocks/rocks.nvim/commit/d09de43611e58a06d0a01f64600cde9fc90d03da))
* **ui:** sync progress percentage computation ([52f1ae6](https://github.com/nvim-neorocks/rocks.nvim/commit/52f1ae6be11ba9a92c967b67e4c1c49f94a9a473))


### Performance Improvements

* auto-populate removable rocks cache ([#70](https://github.com/nvim-neorocks/rocks.nvim/issues/70)) ([7b6d361](https://github.com/nvim-neorocks/rocks.nvim/commit/7b6d361556f4646624b16f4e8677657b0a5939dc))

## [2.2.0](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.1.0...v2.2.0) (2023-12-10)


### Features

* `rocks.api` module for use by external rocks.nvim extensions ([#54](https://github.com/nvim-neorocks/rocks.nvim/issues/54)) ([20dc8ce](https://github.com/nvim-neorocks/rocks.nvim/commit/20dc8cedff23828ffa384a21f127ae2c016675fd))
* **ui:** use fidget.nvim for progress reports ([726d6b5](https://github.com/nvim-neorocks/rocks.nvim/commit/726d6b5ed0d4cfdd1a40f59ab8a28f6417efcd49))


### Bug Fixes

* **completions:** typos that broke `install` and `prund` completions ([edf9120](https://github.com/nvim-neorocks/rocks.nvim/commit/edf9120134e56da934a1607eb581c58bf015f66f))


### Performance Improvements

* populate luarocks.org state cache at startup ([#53](https://github.com/nvim-neorocks/rocks.nvim/issues/53)) ([3b1b5c2](https://github.com/nvim-neorocks/rocks.nvim/commit/3b1b5c28d014f686ba60f00580998ad079214145))

## [2.1.0](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.0.1...v2.1.0) (2023-12-06)


### Features

* `:Rocks prune` command to uninstall rocks and dependencies ([#41](https://github.com/nvim-neorocks/rocks.nvim/issues/41)) ([d0ea65d](https://github.com/nvim-neorocks/rocks.nvim/commit/d0ea65dfcbadcc747b343185a4e85cdb6f7d0ab9))
* add `:Rocks edit` command for opening `rocks.toml` ([#44](https://github.com/nvim-neorocks/rocks.nvim/issues/44)) ([7f92e60](https://github.com/nvim-neorocks/rocks.nvim/commit/7f92e6059685be00bbcf8d29258faa6ea52b6f5c))
* allow users to install development rocks (`scm-1`) ([#36](https://github.com/nvim-neorocks/rocks.nvim/issues/36)) ([3a1fe16](https://github.com/nvim-neorocks/rocks.nvim/commit/3a1fe1614efe97be5cb57d615da7b7ae32c9b5e3))
* **commands:** fuzzy completions ([#49](https://github.com/nvim-neorocks/rocks.nvim/issues/49)) ([ffb7f20](https://github.com/nvim-neorocks/rocks.nvim/commit/ffb7f20edf7f78f83909212643a34ac13c2f0dfb))
* **health:** warn on unrecognized configs / unsourced `vim.g.rocks_nvim` ([#45](https://github.com/nvim-neorocks/rocks.nvim/issues/45)) ([8d51d13](https://github.com/nvim-neorocks/rocks.nvim/commit/8d51d13b1c057c38999d7f82b1be196fe6b5f73a))


### Bug Fixes

* **internal:** use `vim.empty_dict` for better vimscript interop ([#50](https://github.com/nvim-neorocks/rocks.nvim/issues/50)) ([86a8d80](https://github.com/nvim-neorocks/rocks.nvim/commit/86a8d80b32c99e2e46c432af796f6aee2ed6edc8))

## [2.0.1](https://github.com/nvim-neorocks/rocks.nvim/compare/v2.0.0...v2.0.1) (2023-11-28)


### Bug Fixes

* update ROCKS_VERSION, use ROCKS_VERSION in default config ([e7012a0](https://github.com/nvim-neorocks/rocks.nvim/commit/e7012a09c6d32eb4762baf6335834366eaacd153))

## [2.0.0](https://github.com/nvim-neorocks/rocks.nvim/compare/v1.0.1...v2.0.0) (2023-11-28)


### ⚠ BREAKING CHANGES

* remove bootstrapping code from within the plugin

### Features

* add extra description and store data from subbuffers ([6b7e847](https://github.com/nvim-neorocks/rocks.nvim/commit/6b7e847f6bb967d800e7872a56a0ac57f02ffd37))
* add installer skeleton code ([d636e6d](https://github.com/nvim-neorocks/rocks.nvim/commit/d636e6dc66d4753cbf45257a895c844075dbfaf8))
* add more UI elements ([1a4d365](https://github.com/nvim-neorocks/rocks.nvim/commit/1a4d3656a8baf3b0d95c8836d604f7939d7e9fbb))
* add option to auto set up luarocks on the user's machine ([1895d67](https://github.com/nvim-neorocks/rocks.nvim/commit/1895d67f874ad011cf67b6b775a2075d699658cf))
* add support for default values ([590de34](https://github.com/nvim-neorocks/rocks.nvim/commit/590de34d047c4426cf538440da8971b610d62f65))
* add welcome screen to installer ([3bbf317](https://github.com/nvim-neorocks/rocks.nvim/commit/3bbf3178c11c56f340f43426068d022f0a405b31))
* finalize installation process ([5dda747](https://github.com/nvim-neorocks/rocks.nvim/commit/5dda747f93475d59fcc9774295a6386c483ed1a8))
* **installer:** add `&lt;OK&gt;` button ([5984015](https://github.com/nvim-neorocks/rocks.nvim/commit/598401571e384f5213d9fa71cf9584fcf09493d2))
* **installer:** add `luarocks_binary` flag for rocks.nvim configuration ([6f180fe](https://github.com/nvim-neorocks/rocks.nvim/commit/6f180fedbe2733b8e6e92cb1865a8c04ffcab6b7))
* **installer:** add bootstrapping code ([f656883](https://github.com/nvim-neorocks/rocks.nvim/commit/f656883bd81340daa72ba48ab64d5ea5536c0b94))
* **installer:** add luarocks installation code ([d1e234b](https://github.com/nvim-neorocks/rocks.nvim/commit/d1e234be3e8f80350415d86263b6e9c64a96ae96))
* **installer:** error handling ([9abf1e3](https://github.com/nvim-neorocks/rocks.nvim/commit/9abf1e3471f0b3f0170de9517510dd8b582f03ae))
* **installer:** improve "installation complete" screen ([243b55d](https://github.com/nvim-neorocks/rocks.nvim/commit/243b55d2eef7411e01949236e23a40ec884f38ed))
* **installer:** use the neorocks binary server for faster installation ([5bcce43](https://github.com/nvim-neorocks/rocks.nvim/commit/5bcce432c7fea783c3b959388d43e06ccad80568))


### Bug Fixes

* **editorconfig:** failing checks ([8564817](https://github.com/nvim-neorocks/rocks.nvim/commit/8564817b8f499a88a0d4d3564639aaaf8383003c))
* incorrect alignment of centered text with input fields ([c6c5c81](https://github.com/nvim-neorocks/rocks.nvim/commit/c6c5c816560c72e2cde57018f662d90047a30c84))
* **installer:** add extra message when cloning the repository ([6702616](https://github.com/nvim-neorocks/rocks.nvim/commit/6702616db5e9e0f8132a9bb04420aa6e5282e77f))
* **installer:** don't use deprecated API + disable some diagnostics ([bfbebd0](https://github.com/nvim-neorocks/rocks.nvim/commit/bfbebd076ee2b6329c4d8711a75d7a52c172b6ff))
* **installer:** fix column calculations for Neovim instances with line numbers and other obstructions ([105b334](https://github.com/nvim-neorocks/rocks.nvim/commit/105b334b7013fdbae5120fec7f82829329a3fdf6))
* **installer:** install rocks.nvim instead of neorg (was used for testing) ([c9c5c38](https://github.com/nvim-neorocks/rocks.nvim/commit/c9c5c38c81d9ffa6bd934f06f3544b4f3aabab44))
* **installer:** remove missing `,` when copying code to clipboard ([8f7dd57](https://github.com/nvim-neorocks/rocks.nvim/commit/8f7dd5772cf341e3adea6442bad1c12d08fedeec))
* **installer:** type annotations + field names ([13d4592](https://github.com/nvim-neorocks/rocks.nvim/commit/13d45921c0b545d8a901bab48e782ad3e9487678))
* **installer:** use self-contained luarocks binary when possible ([b8a895b](https://github.com/nvim-neorocks/rocks.nvim/commit/b8a895b057ba67daa68cd7b758ea5436a46fadd8))
* try to make installer work ([de31944](https://github.com/nvim-neorocks/rocks.nvim/commit/de31944ae175c82e87453f36a16cd39099ada26d))


### Code Refactoring

* remove bootstrapping code from within the plugin ([ddd2521](https://github.com/nvim-neorocks/rocks.nvim/commit/ddd25217b277ce73db3c9f5f16917b915823452b))

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
