set -gx GOTOOLCHAIN auto
set -gx TERM tmux-256color
set -gx TMPDIR /tmp
set -gx DEVBOX_PATH "$DEVBOX_PACKAGES_DIR/bin/"
if type -q nvim
    set -gx EDITOR nvim
    set -gx MANPAGER "sh -c 'col -b | nvim -R -c \"set ft=man nomod nolist\" -'"
end
