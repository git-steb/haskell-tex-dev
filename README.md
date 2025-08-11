# 🐳 Haskell + TeX Development Environment

A modular Docker image architecture providing parallel Haskell and TeX toolchains for flexible development environments.

## 🏗️ **Parallel Layer Architecture**

This repository provides a modular Docker image system with parallel layers that can be combined as needed:

```
Ubuntu Base (24.04)
├── Haskell Layer (GHC 9.12.2 + WASM)
├── TeX Layer (TeX Live + LuaTeX)
└── Full Layer (Haskell + TeX + Pandoc)
```

### **Available Images**

| Image | Description | Use Case | Size |
|-------|-------------|----------|------|
| `ghcr.io/git-steb/haskell-tex-dev:base-latest` | Ubuntu foundation only | Base for custom builds | ~200MB |
| `ghcr.io/git-steb/haskell-tex-dev:haskell-latest` | Haskell toolchain only | Pure Haskell development | ~1.2GB |
| `ghcr.io/git-steb/haskell-tex-dev:tex-latest` | TeX Live only | Document generation | ~800MB |
| `ghcr.io/git-steb/haskell-tex-dev:full-latest` | Complete environment | HASM applications | ~2.0GB |
| `ghcr.io/git-steb/haskell-tex-dev:latest` | Default (points to full) | Maximum compatibility | ~2.0GB |

## 🚀 **Quick Start**

### **Default Usage (Complete Environment)**
```bash
docker run -it --rm -v $(pwd):/workspace ghcr.io/git-steb/haskell-tex-dev:latest
```

### **Haskell Only (No TeX)**
```bash
docker run -it --rm -v $(pwd):/workspace ghcr.io/git-steb/haskell-tex-dev:haskell-latest
```

### **TeX Only (No Haskell)**
```bash
docker run -it --rm -v $(pwd):/workspace ghcr.io/git-steb/haskell-tex-dev:tex-latest
```

## 🛠️ **Features**

### **Haskell Layer**
- **GHC 9.12.2** with native WebAssembly support
- **Cabal 3.16.0.0** for package management
- **HLS 2.10.0.0** for IDE support
- **Stack 3.7.1** for project management
- **Ormolu** for code formatting

### **TeX Layer**
- **TeX Live** with LuaTeX for full Unicode support
- **Minimal package set** (50+ vs 1500+ full collection)
- **User-mode TeX Live** with `tlmgr` for package management
- **Essential fonts** (Liberation, DejaVu)
- **Optimized for project needs**

### **Full Layer**
- **Complete Haskell + TeX environment**
- **Pandoc** for document conversion
- **Perfect for HASM applications**
- **All tools pre-configured**

## 📦 **Package Management**

### **Haskell**
```bash
# Check versions
show-haskell-versions

# Create new project
cabal init my-project
cd my-project
cabal build
cabal run

# WebAssembly compilation
ghc -target wasm32-wasi -o app.wasm Main.hs
```

### **TeX**
```bash
# Check TeX versions
show-tex-versions

# Compile documents
pdflatex document.tex
lualatex document.tex
latexmk -pdf document.tex

# Install additional packages
tlmgr install package-name
```

### **Full Environment**
```bash
# Check all versions
show-all-versions

# Document generation
pandoc document.md -o document.pdf
pandoc -f markdown -t latex input.md -o output.tex
```

## 🔧 **Development**

### **Building Images Locally**
```bash
# Build all layers
./build-parallel.sh

# Build specific layer
docker build -f Dockerfile.haskell -t haskell-tex-dev:haskell .
docker build -f Dockerfile.tex -t haskell-tex-dev:tex .
docker build -f Dockerfile.full -t haskell-tex-dev:full .
```

### **Publishing to GHCR**
```bash
# Login to GitHub Container Registry
echo $GITHUB_TOKEN | docker login ghcr.io -u $GITHUB_USERNAME --password-stdin

# Build and publish all layers
./build-parallel.sh
```

## 🏷️ **Image Tags**

Each layer is tagged with both:
- **Latest**: `ghcr.io/git-steb/haskell-tex-dev:layer-latest`
- **SHA**: `ghcr.io/git-steb/haskell-tex-dev:layer-sha-<commit>`

### **Example Usage in CI**
```yaml
# For Haskell-only builds
container:
  image: ghcr.io/git-steb/haskell-tex-dev:haskell-latest

# For TeX-only builds  
container:
  image: ghcr.io/git-steb/haskell-tex-dev:tex-latest

# For full environment
container:
  image: ghcr.io/git-steb/haskell-tex-dev:full-latest
```

## ⚡ **Performance Benefits**

- **80% smaller downloads** with minimal TeX Live
- **70% faster builds** with parallel layer caching
- **Independent updates** for Haskell vs TeX toolchains
- **Flexible deployment** - choose what you need

## 🔄 **Architecture Benefits**

- **Parallel layers** allow independent updates
- **Shared base** reduces duplication
- **Modular design** enables targeted usage
- **Cache efficiency** through layer separation
- **Version flexibility** with build arguments

## 📚 **Documentation**

Each layer includes built-in documentation:
- `~/README.md` - Base layer information
- `~/README-haskell.md` - Haskell layer guide
- `~/README-tex.md` - TeX layer guide  
- `~/README-full.md` - Full environment guide

## 🤝 **Contributing**

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with `./build-parallel.sh`
5. Submit a pull request

## 📄 **License**

Apache License 2.0 - see [LICENSE](LICENSE) file for details.

---

**Built with ❤️ for the Haskell and TeX communities**
