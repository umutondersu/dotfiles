set fish_greeting

if status is-interactive
    fzf_configure_bindings --variables=\e\cv --directory=\cf
end

load_env_vars ~/.env
