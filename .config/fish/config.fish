set fish_greeting

if status is-interactive
    # Commands to run in interactive sessions can go here
    set -x GPG_TTY (tty)
    set -x SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
    gpgconf --launch gpg-agent
    fzf_configure_bindings --variables=\e\cv --directory=\cf
end

direnv hook fish | source
load_env_vars ~/.env
