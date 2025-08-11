# syntax=docker/dockerfile:1.4

FROM ubuntu:24.04

LABEL maintainer="git-steb"
LABEL org.opencontainers.image.source="https://github.com/git-steb/haskell-tex-dev"
LABEL org.opencontainers.image.description="Modern Haskell + WASM + TeX Development Environment with GHC 9.12.2 and LaTeX 2025"

# ----- 1. System Prep -----
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    curl wget git zsh gnupg ca-certificates build-essential \
    libgmp-dev zlib1g-dev libtinfo-dev libffi-dev libncurses-dev \
    python3 python3-pip python3-venv \
    xz-utils libgl1-mesa-dev libx11-dev libxft-dev libxext-dev \
    fonts-lmodern software-properties-common sudo unzip \
    perl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ----- 2. Create Non-Root Dev User First -----
RUN useradd -m -s /bin/bash dev && \
    usermod -aG sudo dev && \
    echo "dev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# ----- 3. GHCup Install as Dev User -----
USER dev
WORKDIR /home/dev

RUN curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | BOOTSTRAP_HASKELL_NONINTERACTIVE=1 sh

ENV PATH="/home/dev/.ghcup/bin:${PATH}"

RUN ghcup install ghc 9.12.2 && \
    ghcup set ghc 9.12.2 && \
    ghcup install cabal 3.16.0.0 && \
    ghcup set cabal 3.16.0.0 && \
    ghcup install hls 2.10.0.0 && \
    ghcup set hls 2.10.0.0 && \
    ghcup install stack 3.7.1 && \
    ghcup set stack 3.7.1 && \
    cabal update

# ----- 4. Install Ormolu (after GHC is set up) -----
RUN curl -L https://github.com/tweag/ormolu/releases/latest/download/ormolu-Linux-x86_64 --output ~/.ghcup/bin/ormolu && \
    chmod +x ~/.ghcup/bin/ormolu

# ----- 5. Python Dependencies -----
COPY requirements.txt /tmp/requirements.txt

# ----- 6. Install Lean TeX Live from Ubuntu packages -----
USER root

# Install lean TeX Live base (2023) - just the essentials
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    texlive-base \
    texlive-latex-recommended \
    texlive-fonts-recommended \
    texlive-science \
    texlive-bibtex-extra \
    texlive-lang-english \
    texlive-luatex \
    texlive-xetex \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ----- 7. Install Pandoc and Essential Fonts -----
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    pandoc \
    # Core fonts only - verified to exist
    fonts-liberation \
    fonts-dejavu \
    fonts-noto \
    fonts-ubuntu \
    fonts-linuxlibertine \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ----- 8. Set up user-mode TeX Live for project-specific packages -----
USER dev
WORKDIR /home/dev

# Set up user-mode TeX environment (aligned with ghcup approach)
ENV TEXMFHOME=/home/dev/texmf
ENV PATH="/home/dev/texlive/bin/x86_64-linux:${PATH}"

# Initialize user-mode tlmgr tree and install project-specific packages
RUN tlmgr init-usertree && \
    tlmgr install \
    # Core packages for HomStar project
    minted \
    algorithm2e \
    pdflscape \
    environ \
    trimspaces \
    lineno \
    xpatch \
    # Unicode math and fonts
    unicode-math \
    fontspec \
    xunicode \
    xltxtra \
    # Additional math packages
    amsmath \
    amssymb \
    amsthm \
    mathtools \
    physics \
    siunitx \
    # Code and algorithms
    listings \
    algorithmicx \
    algpseudocode \
    # Tables and graphics
    booktabs \
    array \
    multirow \
    colortbl \
    xcolor \
    # Bibliography and citations
    biblatex \
    biber \
    # Document structure
    geometry \
    fancyhdr \
    titlesec \
    tocloft \
    # Utilities
    etoolbox \
    xparse \
    expl3 \
    # Fonts for Unicode math
    stix2 \
    newtx \
    newpx \
    # Additional useful packages
    microtype \
    hyperref \
    url \
    breakurl \
    # For code highlighting
    fvextra \
    upquote \
    # For better tables
    longtable \
    tabu \
    # For diagrams
    tikz \
    pgf \
    # For cross-references
    cleveref \
    varioref \
    # For better spacing
    setspace \
    # For better lists
    enumitem \
    # For better footnotes
    footmisc \
    # For better captions
    caption \
    subcaption \
    || echo "Some packages may have failed to install, but continuing..."

# ----- 9. Set up Python virtual environment -----
# Create and activate virtual environment
RUN python3 -m venv /home/dev/venv && \
    echo 'source /home/dev/venv/bin/activate' >> ~/.bashrc && \
    echo 'source /home/dev/venv/bin/activate' >> ~/.profile

# Install Python packages in virtual environment
SHELL ["/bin/bash", "-c"]
RUN source /home/dev/venv/bin/activate && \
    pip install --upgrade pip && \
    pip install -r /tmp/requirements.txt

# ----- 10. Set up workspace -----
WORKDIR /workspace

# ----- 11. Health check -----
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD ghc --version && cabal --version && stack --version && ormolu --version && python3 --version && pandoc --version || exit 1

# Default command
CMD ["/bin/bash"] # Trigger rebuild
