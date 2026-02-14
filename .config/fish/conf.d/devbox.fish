if type -q devbox
    # Set SHELL to fish so devbox generates Fish-compatible syntax
    set -gx SHELL fish
    devbox global shellenv --init-hook | source
    # Unset problematic fzf_directory_opts that devbox exports
    set -e fzf_directory_opts
end
