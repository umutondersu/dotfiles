set fish_greeting

if status is-interactive
    set fzf_fd_opts --hidden --exclude=.git
    fzf_configure_bindings --variables=\e\cv --directory=\cf
end

load_env_vars ~/.env
