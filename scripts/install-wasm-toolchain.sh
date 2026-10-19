#!/usr/bin/env bash
# Install an isolated, versioned cross toolchain without changing native CC/Cabal.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${VERSIONS_ENV:-$SCRIPT_DIR/../build_context/versions.env}"
: "${WASM_META_REF:?}" "${GHC_WASM_VERSION:?}" "${WASM_CABAL_VERSION:?}"
prefix="${WASM_INSTALL_ROOT:-$HOME/.local/share/haskell-tex-dev/wasm-$GHC_WASM_VERSION}"
if [[ -f "$prefix/.complete" ]]; then
  echo "WASM toolchain already installed: $prefix"
  exit 0
fi
if [[ -e "$prefix" ]]; then
  echo "Incomplete installation exists at $prefix; inspect it before retrying." >&2
  exit 1
fi
scratch="$(mktemp -d)"
trap 'python3 -c "import shutil,sys; shutil.rmtree(sys.argv[1])" "$scratch"' EXIT
mkdir -p "$scratch/source" "$(dirname "$prefix")"
curl -fsSL "https://github.com/haskell-wasm/ghc-wasm-meta/archive/$WASM_META_REF.tar.gz" -o "$scratch/source.tar.gz"
tar -xzf "$scratch/source.tar.gz" -C "$scratch/source" --strip-components=1
# Upstream resets PREFIX; the guard above ensures this is always a fresh path.
PREFIX="$prefix" FLAVOUR=9.14 SKIP_GHC=1 bash "$scratch/source/setup.sh"
source "$prefix/env"
ghcup --url-source="https://raw.githubusercontent.com/haskell-wasm/ghc-wasm-meta/$WASM_META_REF/ghcup-wasm-0.0.9.yaml" \
  install ghc --no-set "wasm32-wasi-$GHC_WASM_VERSION" -- $CONFIGURE_ARGS
ghcup --url-source="$GHCUP_METADATA_URL" install cabal --no-set "$WASM_CABAL_VERSION"
mkdir -p "$prefix/bin" "$HOME/.local/bin"
ghcup_bin="$(dirname "$(command -v ghcup)")"
for tool in ghc ghc-pkg hsc2hs haddock; do
  cat > "$prefix/bin/wasm32-wasi-$tool" <<EOF
#!/usr/bin/env bash
set -euo pipefail
source "$prefix/env"
exec "$ghcup_bin/wasm32-wasi-$tool-$GHC_WASM_VERSION" "\$@"
EOF
  chmod +x "$prefix/bin/wasm32-wasi-$tool"
  ln -sf "$prefix/bin/wasm32-wasi-$tool" "$HOME/.local/bin/wasm32-wasi-$tool"
done
cat > "$prefix/bin/wasm32-wasi-cabal" <<EOF
#!/usr/bin/env bash
set -euo pipefail
source "$prefix/env"
export CABAL_DIR="$prefix/.cabal"
exec "$ghcup_bin/cabal-$WASM_CABAL_VERSION" \\
  --with-compiler="$prefix/bin/wasm32-wasi-ghc" \\
  --with-hc-pkg="$prefix/bin/wasm32-wasi-ghc-pkg" \\
  --with-hsc2hs="$prefix/bin/wasm32-wasi-hsc2hs" \\
  --with-haddock="$prefix/bin/wasm32-wasi-haddock" "\$@"
EOF
chmod +x "$prefix/bin/wasm32-wasi-cabal"
ln -sf "$prefix/bin/wasm32-wasi-cabal" "$HOME/.local/bin/wasm32-wasi-cabal"
printf 'main = putStrLn "WASM toolchain works"\n' > "$scratch/Main.hs"
cat > "$scratch/toolchain-smoke.cabal" <<'EOF'
cabal-version: 3.0
name: toolchain-smoke
version: 0.1.0
build-type: Simple
executable toolchain-smoke
  main-is: Main.hs
  default-language: GHC2021
  build-depends: base >=4.22 && <4.23
EOF
printf 'packages: .\n' > "$scratch/cabal.project"
(
  cd "$scratch"
  "$prefix/bin/wasm32-wasi-cabal" build --offline
  wasm_binary="$("$prefix/bin/wasm32-wasi-cabal" list-bin exe:toolchain-smoke)"
  "$prefix/wasmtime/bin/wasmtime" "$wasm_binary"
)
printf '%s\n' "$GHC_WASM_VERSION" > "$prefix/.complete"
echo "WASM ready; invoke wasm32-wasi-cabal. Native compiler settings are unchanged."
