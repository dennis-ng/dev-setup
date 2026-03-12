# install apps:
# brew install wezterm neovim lazygit fzf fd bat delta eza tlrc

# Clone fzf-git.sh if not already present
if [ ! -d ~/fzf-git.sh ]; then
    git clone https://github.com/dennis-ng/fzf-git.sh.git ~/fzf-git.sh
    git -C ~/fzf-git.sh checkout 52e3f704767f6cf1dad557220e077fbb40162349
fi

# Copy dotfiles to home (exclude .git, ., ..)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
for f in "$SCRIPT_DIR"/.devtoolsrc "$SCRIPT_DIR"/.wezterm.lua; do
    cp -Rvn "$f" ~
done

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
