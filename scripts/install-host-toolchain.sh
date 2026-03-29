#!/usr/bin/env bash
# Install GHC, Cabal, Stack, and HLS on the host to match build_context/versions.env
# (same pins as the container image tagged from VERSION, e.g. v1.3.0).
#
# Prerequisites: curl. Installs ghcup via https://get-ghcup.haskell.org if missing.
#
# Usage:
#   ./scripts/install-host-toolchain.sh
#   ./scripts/install-host-toolchain.sh --skip-hls
#   ./scripts/install-host-toolchain.sh --dry-run

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VERSIONS_ENV="${REPO_ROOT}/build_context/versions.env"

SKIP_HLS=0
DRY_RUN=0

for arg in "$@"; do
  case "$arg" in
    --skip-hls) SKIP_HLS=1 ;;
    --dry-run)  DRY_RUN=1 ;;
    -h|--help)
      sed -n '1,20p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      exit 1
      ;;
  esac
done

if [[ ! -f "$VERSIONS_ENV" ]]; then
  echo "Missing $VERSIONS_ENV" >&2
  exit 1
fi

# shellcheck source=/dev/null
set -a
# versions.env is KEY=value (no export lines required)
source "$VERSIONS_ENV"
set +a

: "${GHC_VERSION:?}"
: "${CABAL_VERSION:?}"
: "${STACK_VERSION:?}"
: "${HLS_VERSION:?}"
: "${ORMOLU_VERSION:?}"
: "${VERSION:?}"

echo "==> Haskell host toolchain (matches image policy from VERSION=${VERSION})"
echo "    GHC:    ${GHC_VERSION}"
echo "    cabal:  ${CABAL_VERSION}"
echo "    stack:  ${STACK_VERSION}"
echo "    HLS:    $([[ "$SKIP_HLS" -eq 1 ]] && echo skipped || echo "${HLS_VERSION}")"
echo "    Ormolu: ${ORMOLU_VERSION} (release bindist)"
echo ""

run() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[dry-run] $*"
  else
    echo "+ $*"
    "$@"
  fi
}

ensure_ghcup() {
  if command -v ghcup >/dev/null 2>&1; then
    return 0
  fi
  local ghcup_bin="${GHCUP_INSTALL_BASE_PREFIX:-$HOME/.ghcup}/bin/ghcup"
  if [[ -x "$ghcup_bin" ]]; then
    export PATH="$(dirname "$ghcup_bin"):$PATH"
    return 0
  fi
  echo "ghcup not found. Install minimal GHCup bootstrap, then re-run:" >&2
  echo "  curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh" >&2
  echo "Then add ~/.ghcup/bin to PATH (or log in again) and re-run this script." >&2
  exit 1
}

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "(dry-run: skipping ghcup presence check)"
else
  ensure_ghcup
fi

run ghcup upgrade || true

run ghcup install cabal "${CABAL_VERSION}"
run ghcup set cabal "${CABAL_VERSION}"

run ghcup install stack "${STACK_VERSION}"
run ghcup set stack "${STACK_VERSION}"

run ghcup install ghc "${GHC_VERSION}"
run ghcup set ghc "${GHC_VERSION}"

if [[ "$SKIP_HLS" -eq 0 ]]; then
  run ghcup install hls "${HLS_VERSION}"
  run ghcup set hls "${HLS_VERSION}"
fi

echo ""
echo "==> Ormolu (GitHub release bindist — avoids cabal/ghc-lib-parser vs GHC 9.14 mismatch)"
if [[ "$DRY_RUN" -eq 0 ]]; then
  mkdir -p "${HOME}/.local/bin"
fi

install_ormolu_bindist() {
  local dest="${HOME}/.local/bin"
  local url="https://github.com/tweag/ormolu/releases/download/${ORMOLU_VERSION}/ormolu-x86_64-linux.zip"
  local tmp
  tmp="$(mktemp)"
  case "$(uname -s)-$(uname -m)" in
    Linux-x86_64) ;;
    *)
      echo "Ormolu: no official Linux bindist for $(uname -m); skipping (container: same)." >&2
      return 0
      ;;
  esac
  curl -fsSL "$url" -o "$tmp"
  if command -v unzip >/dev/null 2>&1; then
    unzip -qo "$tmp" -d "$dest"
  else
    python3 -c "import zipfile, sys; zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])" "$tmp" "$dest"
  fi
  rm -f "$tmp"
  chmod +x "${dest}/ormolu"
  "${dest}/ormolu" --version
}

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "[dry-run] curl … ormolu-x86_64-linux.zip → ~/.local/bin (ORMOLU_VERSION=${ORMOLU_VERSION})"
else
  install_ormolu_bindist
fi

if [[ "$DRY_RUN" -eq 0 ]]; then
  echo ""
  echo "==> Installed versions:"
  ghc --version || true
  cabal --version || true
  stack --version || true
  if [[ "$SKIP_HLS" -eq 0 ]]; then
    haskell-language-server-wrapper --version 2>/dev/null || haskell-language-server --version 2>/dev/null || true
  fi
  [[ -x "${HOME}/.local/bin/ormolu" ]] && "${HOME}/.local/bin/ormolu" --version || true
  echo ""
  echo "Ensure PATH includes:"
  echo "  export PATH=\"\$HOME/.cabal/bin:\$HOME/.ghcup/bin:\$HOME/.local/bin:\$PATH\""
fi

echo ""
echo "Done. Tool versions are defined in build_context/versions.env (single source of truth)."
