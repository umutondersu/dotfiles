set fish_greeting

# Fisher plugin path (keeps plugin files out of dotfiles)
set --global fisher_path ~/.local/share/fisher
fish_add_path --global $fisher_path/functions
set --global fish_function_path $fisher_path/functions $fish_function_path
set --global fish_complete_path $fisher_path/completions $fish_complete_path
for file in $fisher_path/conf.d/*.fish
    source $file
end

# Symlink fisher themes into fish themes dir (fish has no fish_themes_path)
for theme in $fisher_path/themes/*.theme
    set --local name (basename $theme)
    test -e ~/.config/fish/themes/$name || ln -s $theme ~/.config/fish/themes/$name
end

# Key bindings (vi mode)
set -g fish_key_bindings fish_vi_key_bindings

if status is-interactive
    # Commands to run in interactive sessions can go here
    set -x GPG_TTY (tty)
    if command -q gpgconf
        set -x SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
        gpgconf --launch gpg-agent
    end
    fzf_configure_bindings --variables=\e\cv --directory=\cf
end

load_env_vars ~/.env
