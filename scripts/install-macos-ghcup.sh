#!/usr/bin/env bash
# macOS prerequisite/bootstrap wrapper for the shared pinned host installer.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "install-macos-ghcup: this script is for macOS/Darwin hosts" >&2
  exit 2
fi

export PATH="${HOME}/.cabal/bin:${HOME}/.ghcup/bin:${HOME}/.local/bin:${PATH}"

# Let the shared installer own option parsing. In particular, --help and
# --dry-run must not start a toolchain installation.
case "${1:-}" in
  -h|--help|--dry-run)
    exec "${SCRIPT_DIR}/install-host-toolchain.sh" "$@"
    ;;
esac

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "install-macos-ghcup: missing required command: $1" >&2
    exit 2
  fi
}

need_cmd curl
need_cmd python3

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

exec "${SCRIPT_DIR}/install-host-toolchain.sh" "$@"
