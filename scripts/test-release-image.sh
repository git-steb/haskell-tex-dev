#!/usr/bin/env bash
# Run inside the full image; failures must prevent release promotion.
set -euo pipefail
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
cd "$scratch"
ghc --version
cabal --version
stack --version
ormolu --version
haskell-language-server-wrapper --version
printf 'main = putStrLn "native compiler works"\n' > Main.hs
ghc -O1 Main.hs -o smoke
[[ $(./smoke) == 'native compiler works' ]]
printf '%s\n' '\documentclass{article}' '\begin{document}Environment smoke test.\end{document}' > smoke.tex
latexmk -pdf -interaction=nonstopmode -halt-on-error smoke.tex
test -s smoke.pdf
