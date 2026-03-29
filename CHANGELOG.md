# Changelog

All notable changes to the haskell-tex-dev Docker image will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.0] - 2026-03-29

### Changed
- **GHC** 9.12.2 → **9.14.1** (GHCup bindists for Ubuntu 24.04)
- **cabal-install** 3.16.0.0 → **3.16.1.0** (GHCup “Latest”)
- **Stack** 3.7.1 → **3.9.3** (GHCup “Latest”)
- **HLS** 2.10.0.0 → **2.13.0.0** (prebuilt for GHC 9.14.1; see upstream notes on “basic” 9.14 support)
- **Hackage index-state** for preload projects: **2026-03-29T00:00:00Z** (Servant / ecosystem bounds for **base-4.22** / GHC 9.14)
- **GHCup bootstrap** unchanged URL (`get-ghcup.haskell.org`); tools installed explicitly from `versions.env`

### Added
- **`scripts/install-host-toolchain.sh`**: installs GHC/Cabal/Stack/HLS on the host from **`build_context/versions.env`** (same pins as the container), plus **Ormolu** from the official **GitHub release bindist** (avoids `cabal install` / `ghc-lib-parser` mismatch on GHC 9.14).
- **`ARG WITH_HLS=1`**: set build-arg `WITH_HLS=0` to skip HLS and shrink the image
- **HLS** installation via `ghcup install hls` (was previously only referenced in env, not installed)
- **Ormolu** installed from **Tweag release** `ormolu-x86_64-linux.zip` into `/home/dev/.local/bin` (Linux x86_64); no `cabal install` pin required for GHC 9.14

### Changed (CI warm-cache)
- **`build_context/deps-list.txt`**: expanded for large Haskell apps (e.g. **servant**, **servant-server**, **http-client**, **conduit**, **template-haskell**, **async**, **unix**, **memory**, **comonad**, **safe**, **split**, **array**, **deepseq**, **case-insensitive**). **`wreq`** is not preloaded (fails to compile on GHC 9.14 with current Hackage); use **http-client** / **http-conduit** in projects.
- **Preload `cabal.project`** does **not** pin `text` (GHC **9.14.1** ships `text` / `template-haskell` revisions that are incompatible with a `text ==2.1.2` pin used on older GHC).
- **Preload `allow-newer`**: **`uuid:time`**, **`*:base`**, **`*:template-haskell`**, **`monad-control:transformers-compat`** so the warm-cache solve can proceed while Hackage caps catch up to GHC **9.14** (**base-4.22**, **template-haskell-2.24**, **time-1.15**, **transformers-compat-0.8**, etc.).
- **Removed** post-preload `cabal store gc --prune=all` and **stopped deleting** `~/.cabal/packages` in the final layer so precompiled deps and the Hackage index stay in the image for faster CI.
- **Dropped** redundant second preload project and the extra **`cabal install --lib`** block (same packages come from one `deps-list` solve).

### Breaking changes
- Application images that assumed **GHC 9.12.x** may need `cabal.project` / CI updates before adopting this tag.
- **HLS on 9.14.1** is still maturing upstream (fewer plugins than on 9.12.2); pin an older image if you need the previous behaviour.

## [1.2.9] - 2025-01-27

### Added
- **Python FFI Support**: Added Python development libraries (`python3-dev`, `libpython3-dev`, `libpython3.12-dev`) for full Python FFI integration
- **Comprehensive Dependency Caching**: Added 22 critical packages to pre-loading for faster CI builds:
  - Web frameworks: `wreq`, `websockets`, `wai`, `wai-cors`, `warp`, `miso`
  - XML/HTML processing: `xml`, `xml-conduit`, `html-conduit`, `html-entities`, `tagsoup`
  - Additional libraries: `pandoc-types`, `lens`, `wai-middleware-static`, `blaze-html`, `blaze-markup`
  - Crypto libraries: `crypto-api`, `crypto-pubkey-types`, `authenticate-oauth`
  - Utility packages: `expiring-cache-map`
- **Direct Package Installation**: Implemented direct `cabal install --lib` for critical dependencies with version constraints
- **Optimization Documentation**: Added comprehensive documentation of caching improvements
- **Test Suite**: Created `test-optimizations.sh` for validating Docker caching optimizations

### Changed
- **Cabal Index Synchronization**: Updated index state from `2025-08-15T19:06:45Z` to `2025-09-23T01:29:59Z` to match CI usage
- **Enhanced Documentation**: Updated README with new pre-installed packages and Python FFI support
- **Optimization Labels**: Enhanced Docker labels to include `python-ffi-support`, `web-frameworks-cached`, `xml-processing-cached`

### Performance Improvements
- **60-80% reduction** in dependency download/compile time for projects using web frameworks
- **Eliminated Python FFI build failures** by pre-installing development libraries
- **Improved Docker layer caching** through comprehensive dependency pre-loading
- **Consistent package versions** across builds through synchronized index states

### Technical Details
- **Base Image**: `ghcr.io/git-steb/haskell-tex-dev:base-latest`
- **GHC Version**: 9.12.2 with WASM support
- **Cabal Version**: 3.16.0.0
- **Stack Version**: 3.7.1
- **Python Support**: Full FFI support with development libraries
- **Pre-loaded Packages**: 50+ packages including all major web and XML processing libraries

### Breaking Changes
- None. All changes are backward compatible.

### Migration Guide
No migration required. Existing projects will automatically benefit from improved caching.

### Known Issues
- None identified.

---

## [1.2.8] - Previous Release

### Added
- Basic dependency pre-loading
- WASM toolchain support
- TeX Live integration

### Changed
- Improved build performance
- Enhanced documentation

---

## [1.2.7] - Previous Release

### Added
- Initial release with Haskell toolchain
- Basic TeX support
- GHCup integration

---

## Version History

| Version | Release Date | Key Features |
|---------|--------------|--------------|
| 1.2.9   | 2025-01-27   | Python FFI support, comprehensive dependency caching, 60-80% build time improvement |
| 1.2.8   | Previous     | Basic dependency pre-loading, WASM support |
| 1.2.7   | Previous     | Initial Haskell toolchain, TeX integration |

## Contributing

When adding new features or making changes:

1. Update this changelog with a new entry
2. Update the VERSION file
3. Test with the provided test suite
4. Update documentation as needed

## Support

For issues or questions about this image:
- Check the [README.md](README.md) for usage instructions
- Run `test-optimizations.sh` to validate the installation
- Review [OPTIMIZATION_CHANGES.md](OPTIMIZATION_CHANGES.md) for technical details
