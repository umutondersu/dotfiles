set fish_greeting

if status is-interactive
  # Commands to run in interactive sessions can go here
  set -x GPG_TTY (tty)
  set -x SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
  gpgconf --launch gpg-agent
  fzf_configure_bindings --directory=\cf --variables=\e\cv
end

zoxide init --cmd cd fish | source

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH
