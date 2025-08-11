# Haskell + TeX Development Environment

A production-ready Docker image for modern Haskell and LaTeX development, featuring GHC 9.12.2, Cabal 3.16.0.0, full TeXLive 2025, and Pandoc support.

## 🚀 Quick Start

### For CI/CD (GitHub Actions)

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/git-steb/haskell-tex-dev:latest
    steps:
      - uses: actions/checkout@v4
      - run: cabal build
```

### For Local Development

```bash
# Pull the image
docker pull ghcr.io/git-steb/haskell-tex-dev:latest

# Run interactively
docker run -it --rm \
  -v "$(pwd):/workspace" \
  -w /workspace \
  ghcr.io/git-steb/haskell-tex-dev:latest

# Run a specific command
docker run --rm \
  -v "$(pwd):/workspace" \
  -w /workspace \
  ghcr.io/git-steb/haskell-tex-dev:latest \
  cabal build
```

## 📦 Included Tools

### Haskell Toolchain
- **GHC**: 9.12.2 (latest stable via GHCup)
- **Cabal**: 3.16.0.0 (modern build system)
- **Stack**: 3.7.1 (reproducible builds)
- **Ormolu**: Latest (deterministic code formatting, installed from official binary)
- **HLS**: 2.10.0.0 (Haskell Language Server)

### LaTeX Environment
- **TeXLive**: 2023 (recommended distribution via apt)
- **Pandoc**: Latest version for document conversion
- **Essential Packages**: Included in texlive-latex-recommended and texlive-latex-extra (algorithm2e, minted, biblatex, biber, microtype, booktabs, colortbl, pdflscape, environ, trimspaces, ulem, xcolor, soul, listings, fancyvrb, framed, lineno, xpatch, etoolbox)

### Python Support
- **Python**: 3.12 (via virtual environment)
- **Packages**: pyyaml, click, colorama, jinja2, markdown, beautifulsoup4, lxml, requests

### System Tools
- **Build Tools**: build-essential, libgmp-dev, zlib1g-dev, libtinfo-dev, libffi-dev
- **Development**: git, curl, wget, sudo
- **Fonts**: fonts-lmodern

## 🔥 Tool Choices - Why These Work

### **GHC 9.12.2** - Latest Stable
- Recent enough for modern libraries
- Excellent performance improvements
- Full support for latest language extensions

### **Cabal 3.16.0.0** - Modern Build System
- Matches GHC 9.12 series perfectly
- Better solver behavior for dependency resolution
- New-style builds with improved caching

### **Stack 3.7.1** - Reproducible Builds
- Perfect backup for complex dependency scenarios
- Excellent for team projects requiring specific snapshots
- Great for projects that need reproducible builds

### **Ormolu** - Deterministic Formatting
- Installed from official binary release (latest version)
- No configuration debates - consistent style
- Fast and reliable
- Integrates well with modern tooling

### **HLS 2.10.0.0** - IDE Excellence
- Matches your GHC version for smooth integration
- Provides full IDE features: completion, refactoring, error checking
- Automatically detects GHC version and provides appropriate support

## 🏗️ Building Locally

```bash
# Clone this repository
git clone https://github.com/git-steb/haskell-tex-dev.git
cd haskell-tex-dev

# Build the image
docker build -t haskell-tex-dev:local .

# Test the build
docker run --rm haskell-tex-dev:local ghc --version
docker run --rm haskell-tex-dev:local cabal --version
docker run --rm haskell-tex-dev:local pandoc --version
```

## 🏷️ Available Tags

- `latest` - Most recent stable build
- `vX.Y.Z` - Versioned releases (e.g., `v0.1.0`)
- `ghc-9.12.2` - Specific GHC version
- `texlive-2025` - Specific TeXLive version

## 🔧 Customization

### Adding More TeX Packages

Edit the Dockerfile and add packages to the `tlmgr install` section:

```dockerfile
RUN tlmgr install \
    your-package-1 \
    your-package-2 \
    && tlmgr path add
```

### Adding Python Packages

Edit `contracts/scripts/requirements.txt` and add your dependencies:

```txt
pyyaml>=6.0
your-package>=1.0.0
```

### Using Different GHC Versions

Modify the GHCup installation section in the Dockerfile:

```dockerfile
RUN ghcup install ghc 9.12.3 && \
    ghcup set ghc 9.12.3
```

## 🧪 Testing the Environment

The image includes a health check that verifies all major tools:

```bash
# Health check runs automatically
docker run --rm ghcr.io/git-steb/haskell-tex-dev:latest

# Manual verification
docker run --rm ghcr.io/git-steb/haskell-tex-dev:latest bash -c "
  echo '=== Haskell ===' && ghc --version && cabal --version
  echo '=== Python ===' && python3 --version
  echo '=== Pandoc ===' && pandoc --version
  echo '=== TeX ===' && pdflatex --version
"
```

## 📋 Use Cases

### Academic Writing
- LaTeX documents with complex mathematical notation
- Bibliography management with BibLaTeX
- Algorithm typesetting with algorithm2e
- Code listings with minted

### Haskell Development
- Modern GHC development with latest features
- Cabal-based project management
- HLS for IDE support
- Testing and benchmarking

### Documentation
- Pandoc for format conversion
- Markdown to PDF/LaTeX conversion
- Technical documentation with code examples

## 🔄 CI/CD Integration

### GitHub Actions Example

```yaml
name: Build and Test
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/git-steb/haskell-tex-dev:latest
    steps:
      - uses: actions/checkout@v4
      - name: Build Haskell
        run: |
          cd minimal
          cabal build
      - name: Run Tests
        run: |
          cd minimal
          cabal test
      - name: Generate Documentation
        run: |
          cd minimal
          cabal haddock
      - name: Build LaTeX
        run: |
          cd docs
          pdflatex document.tex
```

### GitLab CI Example

```yaml
image: ghcr.io/git-steb/haskell-tex-dev:latest

stages:
  - build
  - test

build:
  stage: build
  script:
    - cabal build

test:
  stage: test
  script:
    - cabal test
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the build locally
5. Submit a pull request

### Development Workflow

```bash
# Make changes to Dockerfile
docker build -t haskell-tex-dev:test .

# Test your changes
docker run --rm haskell-tex-dev:test bash -c "
  # Your test commands here
"

# If satisfied, commit and push
git add .
git commit -m "feat: Add new TeX package"
git push origin feature-branch
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [GHCup](https://www.haskell.org/ghcup/) for Haskell toolchain management
- [TeXLive](https://www.tug.org/texlive/) for LaTeX distribution
- [Pandoc](https://pandoc.org/) for document conversion
- [GitHub Container Registry](https://ghcr.io/) for image hosting

## 📞 Support

For issues, questions, or contributions:
- Open an issue on GitHub
- Check the [GitHub Actions](https://github.com/git-steb/haskell-tex-dev/actions) for build status
- Review the [releases](https://github.com/git-steb/haskell-tex-dev/releases) for version history 