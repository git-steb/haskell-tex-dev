#!/usr/bin/env bash
# Install GHC, Cabal, Stack, and HLS on the host to match build_context/versions.env
# (same pins as the container image tagged from VERSION, e.g. v1.4.0).
#
# Prerequisites: curl, python3 and GHCup (bootstrap instructions below).
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

set -a
# versions.env is KEY=value (no export lines required)
# shellcheck source=/dev/null
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
    PATH="$(dirname "$ghcup_bin"):$PATH"
    export PATH
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

run ghcup --url-source="${GHCUP_METADATA_URL:?}" install cabal "${CABAL_VERSION}"
run ghcup set cabal "${CABAL_VERSION}"

run ghcup --url-source="${GHCUP_METADATA_URL}" install stack "${STACK_VERSION}"
run ghcup set stack "${STACK_VERSION}"

run ghcup --url-source="${GHCUP_METADATA_URL}" install ghc "${GHC_VERSION}"
run ghcup set ghc "${GHC_VERSION}"

if [[ "$SKIP_HLS" -eq 0 ]]; then
  run ghcup --url-source="${GHCUP_METADATA_URL}" install hls "${HLS_VERSION}"
  run ghcup set hls "${HLS_VERSION}"
fi

echo ""
echo "==> Ormolu (GitHub release bindist — avoids cabal/ghc-lib-parser vs GHC 9.14 mismatch)"
if [[ "$DRY_RUN" -eq 0 ]]; then
  mkdir -p "${HOME}/.local/bin"
fi

install_ormolu_bindist() {
  local dest="${HOME}/.local/bin"
  local asset
  asset="$(ormolu_asset)"
  local url="https://github.com/tweag/ormolu/releases/download/${ORMOLU_VERSION}/${asset}"
  local tmp
  tmp="$(mktemp)"
  curl -fsSL "$url" -o "$tmp"
  # Stage the complete bindist. macOS archives include dylibs referenced via
  # @executable_path, so extracting only `ormolu` produces a binary that aborts
  # at launch. Replace support files first and the executable last.
  python3 - "$tmp" "$dest" <<'PY'
import os, pathlib, sys, tempfile, zipfile
archive, destination = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
try:
    with zipfile.ZipFile(archive) as release, tempfile.TemporaryDirectory(
        dir=destination, prefix=".ormolu-"
    ) as staging_name:
        staging = pathlib.Path(staging_name)
        members = []
        for info in release.infolist():
            if info.is_dir():
                continue
            name = pathlib.PurePosixPath(info.filename)
            if len(name.parts) != 1:
                raise RuntimeError(f"unexpected path in Ormolu archive: {info.filename}")
            target = staging / name.name
            target.write_bytes(release.read(info))
            target.chmod(0o755 if name.name == "ormolu" else 0o644)
            members.append(name.name)
        if "ormolu" not in members:
            raise RuntimeError("Ormolu archive contains no ormolu executable")
        for name in sorted(member for member in members if member != "ormolu"):
            os.replace(staging / name, destination / name)
        os.replace(staging / "ormolu", destination / "ormolu")
finally:
    archive.unlink(missing_ok=True)
PY
  "${dest}/ormolu" --version
}

ormolu_asset() {
  case "$(uname -s)-$(uname -m)" in
    Linux-x86_64) echo ormolu-x86_64-linux.zip ;;
    Darwin-arm64|Darwin-aarch64) echo ormolu-aarch64-darwin.zip ;;
    Darwin-x86_64) echo ormolu-x86_64-darwin.zip ;;
    *) echo "No official Ormolu bindist for $(uname -s)-$(uname -m)." >&2; return 1 ;;
  esac
}

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "[dry-run] curl … $(ormolu_asset) → ~/.local/bin (ORMOLU_VERSION=${ORMOLU_VERSION})"
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
