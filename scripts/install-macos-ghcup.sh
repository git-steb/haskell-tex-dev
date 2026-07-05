#!/usr/bin/env bash
set -euo pipefail

# Install the macOS host Haskell toolchain using the same GHCup-versioned
# policy as build_context/Dockerfile.haskell.
#
# This intentionally does not install Homebrew. Homebrew is optional for this
# repo's Haskell path; GHCup is the unifier.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "install-macos-ghcup: this script is for macOS/Darwin hosts" >&2
  exit 2
fi

# shellcheck disable=SC1091
source "${REPO_ROOT}/build_context/versions.env"

export PATH="${HOME}/.cabal/bin:${HOME}/.ghcup/bin:${HOME}/.local/bin:${PATH}"

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "install-macos-ghcup: missing required command: $1" >&2
    exit 2
  fi
}

need_cmd curl
need_cmd tar
need_cmd git

if ! xcode-select -p >/dev/null 2>&1; then
  echo "install-macos-ghcup: Xcode Command Line Tools are required." >&2
  echo "Run: xcode-select --install" >&2
  exit 2
fi

if ! command -v ghcup >/dev/null 2>&1; then
  echo "install-macos-ghcup: installing GHCup into ${HOME}/.ghcup"
  curl -fsSL https://get-ghcup.haskell.org \
    | BOOTSTRAP_HASKELL_NONINTERACTIVE=1 \
      BOOTSTRAP_HASKELL_MINIMAL=1 \
      GHCUP_INSTALL_BASE_PREFIX="${HOME}" \
      sh
fi

echo "install-macos-ghcup: using versions from build_context/versions.env"
echo "  GHC_VERSION=${GHC_VERSION}"
echo "  CABAL_VERSION=${CABAL_VERSION}"
echo "  STACK_VERSION=${STACK_VERSION}"

ghcup install ghc "${GHC_VERSION}"
ghcup set ghc "${GHC_VERSION}"

ghcup install cabal "${CABAL_VERSION}"
ghcup set cabal "${CABAL_VERSION}"

ghcup install stack "${STACK_VERSION}"
ghcup set stack "${STACK_VERSION}"

echo
echo "install-macos-ghcup: verification"
ghc --version
cabal --version
stack --version

echo
echo "install-macos-ghcup: PATH reminder"
echo '  export PATH="$HOME/.cabal/bin:$HOME/.ghcup/bin:$HOME/.local/bin:$PATH"'
