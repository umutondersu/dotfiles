if type -q devbox
    devbox global shellenv --init-hook | source
    # Unset problematic fzf_directory_opts that devbox exports
    # It contains invalid syntax that breaks fzf keybindings
    set -e fzf_directory_opts
end
