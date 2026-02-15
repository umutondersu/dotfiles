if type -q rip
    abbr --add --set-cursor rs "rip search deezer track '%'"
    abbr --add --set-cursor rt "rip search deezer track '%'"
    abbr --add --set-cursor ra "rip search deezer album '%'"
    abbr --add --set-cursor ru "rip search deezer url '%'"
end

if type -q devbox
    abbr --add db devbox
    abbr --add ds devbox search
    abbr --add dS devbox shell
    abbr --add dg devbox global
    abbr --add da devbox global add
    abbr --add dr devbox global rm
    abbr --add dl devbox global list
end

if type -q nvim
    abbr --add v nvim
    abbr --add V --position anywhere "&& nvim"
    abbr --add nvim-min 'NVIM_APPNAME="nvim-min" nvim'
    abbr --add vm 'NVIM_APPNAME="nvim-min" nvim'
end

if type -q spf
    abbr --add s spf
end

if type -q lazygit
    abbr --add lg lazygit
end

if type -q bunx
    abbr --add shad bunx --bun shadcn@latest
end

if type -q lsd
    abbr --add lT ls --tree --depth 2
    abbr --add lt 'ls -I node_modules -I dist -I build -I target -I out -I tmp -I __pycache__ --tree --depth 2'
end
abbr --add l ls
abbr --add ll ls -lg
abbr --add la ls -A
abbr --add lla ls -lgA
abbr --add lS ls -lgSA

abbr c --add cd
abbr g --add git

abbr --add odlog journalctl --user-unit=onedrive -f
abbr --add claer clear
abbr --add clr clear
abbr --add python python3
abbr --add fkill sudo kill -9
abbr --add Y --position anywhere "| xclip -selection clipboard"
abbr --add P "xclip -selection clipboard -o >"
abbr --add B --position anywhere ">/dev/null &"
abbr --add update 'sudo apt update && sudo apt upgrade -y && flatpak update -y'
abbr --add --set-cursor tc tar -czvf %.tar.gz ./
abbr --add --set-cursor td tar -xzf %.tar.gz
abbr --add src source
