# syntax=docker/dockerfile:1.4

FROM ubuntu:24.04

LABEL maintainer="git-steb"
LABEL org.opencontainers.image.source="https://github.com/git-steb/homeomorphosis"
LABEL org.opencontainers.image.description="Modern Haskell + WASM + TeX Development Environment with GHC 9.12.2 and LaTeX 2025"

# ----- 1. System Prep -----
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    curl wget git zsh gnupg ca-certificates build-essential \
    libgmp-dev zlib1g-dev libtinfo-dev libffi-dev libncurses-dev \
    python3 python3-pip python3-venv \
    xz-utils libgl1-mesa-dev libx11-dev libxft-dev libxext-dev \
    fonts-lmodern software-properties-common sudo unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ----- 2. GHCup Install -----
RUN curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | BOOTSTRAP_HASKELL_NONINTERACTIVE=1 sh

ENV PATH="/root/.ghcup/bin:${PATH}"

RUN ghcup install ghc 9.12.2 && \
    ghcup set ghc 9.12.2 && \
    ghcup install cabal 3.16.0.0 && \
    ghcup set cabal 3.16.0.0 && \
    ghcup install hls 2.10.0.0 && \
    ghcup set hls 2.10.0.0 && \
    cabal update

# ----- 3. Python Dependencies -----
COPY requirements.txt /tmp/requirements.txt
RUN python3 -m pip install --upgrade pip && \
    pip install -r /tmp/requirements.txt

# ----- 4. Install TeX Live with essential packages -----
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    texlive-full \
    texlive-latex-extra \
    texlive-science \
    texlive-publishers \
    texlive-fonts-extra \
    texlive-bibtex-extra \
    texlive-lang-english \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ----- 5. Install Pandoc and essential TeX packages -----
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    pandoc \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install essential TeX packages via tlmgr (focused selection)
RUN tlmgr update --self && \
    tlmgr install \
    algorithm2e \
    minted \
    biblatex \
    biber \
    microtype \
    booktabs \
    colortbl \
    pdflscape \
    environ \
    trimspaces \
    ulem \
    xcolor \
    soul \
    listings \
    fancyvrb \
    framed \
    lineno \
    xpatch \
    etoolbox \
    && tlmgr path add

# ----- 6. Set up workspace -----
WORKDIR /workspace

# ----- 7. Create non-root user for development -----
RUN useradd -m -s /bin/bash dev && \
    usermod -aG sudo dev && \
    echo "dev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# ----- 8. Set up user environment -----
USER dev
WORKDIR /home/dev

# Add GHCup to user PATH
RUN echo 'export PATH="/root/.ghcup/bin:$PATH"' >> ~/.bashrc && \
    echo 'export PATH="/root/.ghcup/bin:$PATH"' >> ~/.profile

# ----- 9. Health check -----
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD ghc --version && cabal --version && python3 --version && pandoc --version || exit 1

# Default command
CMD ["/bin/bash"] 