set -gx GOTOOLCHAIN auto
set -gx TERM tmux-256color
set -gx TMPDIR /tmp
set -gx DEVBOX_PATH "$DEVBOX_PACKAGES_DIR/bin/"
set -gx fisher_path $HOME/.local/share/fisher
if type -q nvim
    set -gx EDITOR nvim
    set -gx MANPAGER "nvim +Man! -"
end
