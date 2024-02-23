# Changelog

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
