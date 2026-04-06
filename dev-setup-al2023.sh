#!/bin/bash
set -e

# Dev tools setup for Amazon Linux 2023 (AL2023)
# Installs: neovim, lazygit, fzf, fd, bat, delta, eza, tlrc

echo "=== Installing build tools ==="
sudo dnf groupinstall -y "Development Tools"

echo "=== Installing Neovim ==="
curl -fLo /tmp/nvim-linux-x86_64.tar.gz "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"
tar xf /tmp/nvim-linux-x86_64.tar.gz -C /tmp
sudo cp -r /tmp/nvim-linux-x86_64/* /usr/local/
rm -rf /tmp/nvim-linux-x86_64 /tmp/nvim-linux-x86_64.tar.gz

echo "=== Installing fzf ==="
if [ ! -d ~/.fzf ]; then
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
fi
~/.fzf/install --all

echo "=== Installing Rust toolchain ==="
if ! command -v cargo &>/dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
fi

echo "=== Installing Rust-based tools (eza, bat, delta, fd, tlrc) ==="
cargo install eza bat git-delta fd-find tlrc

echo "=== Installing lazygit ==="
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | sed -n 's/.*"tag_name": "v\([^"]*\)".*/\1/p')
curl -fLo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf /tmp/lazygit.tar.gz -C /tmp lazygit
sudo install /tmp/lazygit /usr/local/bin
rm /tmp/lazygit /tmp/lazygit.tar.gz

echo "=== Setting up dotfiles ==="
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Clone fzf-git.sh if not already present
if [ ! -d ~/fzf-git.sh ]; then
    git clone https://github.com/dennis-ng/fzf-git.sh.git ~/fzf-git.sh
    git -C ~/fzf-git.sh checkout 52e3f704767f6cf1dad557220e077fbb40162349
fi

# Copy dotfiles to home
for f in "$SCRIPT_DIR"/.devtoolsrc "$SCRIPT_DIR"/.wezterm.lua; do
    cp -Rvn "$f" ~
done
mkdir -p ~/.config
cp -Rvn "$SCRIPT_DIR"/.config/* ~/.config/

# Append devtoolsrc sourcing to ~/.zshrc if not already present
ZSHRC_SNIPPET='if [ -f ~/.devtoolsrc ]; then
    source ~/.devtoolsrc
fi'

if ! grep -qF 'source ~/.devtoolsrc' ~/.zshrc 2>/dev/null; then
    printf '\n%s\n' "$ZSHRC_SNIPPET" >> ~/.zshrc
    echo "Added devtoolsrc sourcing to ~/.zshrc"
else
    echo "~/.zshrc already sources ~/.devtoolsrc"
fi

echo "=== Installing Neovim plugins ==="
nvim --headless "+Lazy! sync" +qa

echo "=== Done! Restart your shell or run: source ~/.zshrc ==="
