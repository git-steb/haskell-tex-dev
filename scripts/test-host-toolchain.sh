#!/usr/bin/env bash
# Verify the pinned native host toolchain without touching a consumer checkout.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

set -a
# shellcheck source=/dev/null
source "${REPO_ROOT}/build_context/versions.env"
set +a

export PATH="${HOME}/.cabal/bin:${HOME}/.ghcup/bin:${HOME}/.local/bin:${PATH}"

require_version() {
  local label="$1"
  local expected="$2"
  shift 2
  local output
  output="$("$@" 2>&1)"
  if [[ "$output" != *"$expected"* ]]; then
    echo "${label}: expected ${expected}, got: ${output}" >&2
    exit 1
  fi
  echo "${label}: ${expected}"
}

require_version GHC "$GHC_VERSION" ghc --numeric-version
require_version cabal "$CABAL_VERSION" cabal --numeric-version
require_version Stack "$STACK_VERSION" stack --numeric-version
require_version HLS "$HLS_VERSION" haskell-language-server-wrapper --version
require_version Ormolu "$ORMOLU_VERSION" ormolu --version

scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT

cat >"${scratch}/host-toolchain-smoke.cabal" <<'EOF'
cabal-version: 3.0
name: host-toolchain-smoke
version: 0.1.0.0
build-type: Simple

executable host-toolchain-smoke
  main-is: Main.hs
  build-depends: base >=4.22 && <4.23
  default-language: GHC2024
  ghc-options: -Wall -Werror
EOF

cat >"${scratch}/Main.hs" <<'EOF'
module Main (main) where

main :: IO ()
main = putStrLn "GHC 9.14 host toolchain works"
EOF

ormolu --mode inplace "${scratch}/Main.hs"
(
  cd "$scratch"
  cabal build --offline exe:host-toolchain-smoke
  smoke="$(cabal list-bin exe:host-toolchain-smoke)"
  [[ "$($smoke)" == "GHC 9.14 host toolchain works" ]]
)

(
  cd "$scratch"
  haskell-language-server-wrapper --probe-tools >/dev/null
)
echo "Host toolchain smoke test passed."
