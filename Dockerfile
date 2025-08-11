# Default Dockerfile: Points to the full layer for maximum compatibility
# This provides the complete Haskell + TeX environment for most use cases
FROM ghcr.io/git-steb/haskell-tex-dev:full-latest

# The full layer includes:
# - GHC 9.12.2 with native WASM support
# - TeX Live with LuaTeX for full Unicode support
# - Pandoc for document conversion
# - Complete toolchain for HASM applications

# For lighter alternatives, use:
# - ghcr.io/git-steb/haskell-tex-dev:haskell-latest (Haskell only)
# - ghcr.io/git-steb/haskell-tex-dev:tex-latest (TeX only)
# - ghcr.io/git-steb/haskell-tex-dev:base-latest (Ubuntu foundation only)

LABEL maintainer="git-steb"
LABEL org.opencontainers.image.source="https://github.com/git-steb/haskell-tex-dev"
LABEL org.opencontainers.image.description="Complete Haskell + TeX development environment"
LABEL org.opencontainers.image.title="Haskell TeX Dev"
LABEL usage="docker run -it --rm -v \$(pwd):/workspace ghcr.io/git-steb/haskell-tex-dev:latest"
