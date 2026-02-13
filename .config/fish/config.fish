set fish_greeting

# Key bindings (vi mode)
set -g fish_key_bindings fish_vi_key_bindings

if status is-interactive
    # Commands to run in interactive sessions can go here
    set -x GPG_TTY (tty)
    set -x SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
    gpgconf --launch gpg-agent
    fzf_configure_bindings --variables=\e\cv --directory=\cf
end

if type -q direnv
    direnv hook fish | source
end
load_env_vars ~/.env
