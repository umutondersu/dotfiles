set -gx GOTOOLCHAIN auto
set -gx TMPDIR /tmp
set -gx fisher_path $HOME/.local/share/fisher
if type -q nvim
    set -gx EDITOR nvim
    set -gx MANPAGER "nvim +Man! -"
    set -gx SUDO_EDITOR (which nvim)
end
