if type -q rip
    function _abbr_rip_url
        clip_expand "rip url '%'"
    end
    abbr --add --set-cursor rs "rip search deezer track '%'"
    abbr --add --set-cursor ra "rip search deezer album '%'"
    abbr --add ru --function _abbr_rip_url
end

if type -q devbox
    abbr --add db devbox
    abbr --add ds devbox search
    abbr --add dS devbox shell
    abbr --add dgc "devbox global run -- nix store gc --extra-experimental-features nix-command"

    abbr --add dg devbox global
    abbr --add da devbox global add
    abbr --add dgu devbox global update
    abbr --add drm devbox global rm
    abbr --add dl devbox global list

    abbr --add dA devbox add
    abbr --add dU devbox update
    abbr --add dr devbox run
    abbr --add dRm devbox rm
    abbr --add dL devbox list
end

if type -q nix
    abbr --add --set-cursor nr "nix run nixpkgs#%"
    abbr --add --set-cursor ns "nix shell nixpkgs#%"
    abbr --add gob "nix shell nixpkgs#go nixpkgs#go-blueprint -c go-blueprint create --advanced"
    abbr --add --set-cursor np --position anywhere "nixpkgs#%"
    abbr --add ngc nix store gc
    abbr --add --position anywhere nf nixfind
    if type -q nix-search
        abbr --add nS nix-search
    else
        abbr --add nS nix search
    end
end

if type -q nvim
    abbr --add v nvim
    abbr --add V --position anywhere "&& nvim"
    abbr --add vm 'NVIM_APPNAME="nvim-min" nvim'
end

if type -q opencode
    abbr --add o opencode
end

if type -q spf
    abbr --add s spf
end

if type -q lazygit
    abbr --add lg lazygit
    abbr --add G lazygit
end

if type -q bunx
    abbr --add shad bunx --bun shadcn@latest
end

if type -q lsd
    abbr --add lT ls --tree --depth 2
    abbr --add lt 'ls -I node_modules -I dist -I build -I target -I out -I tmp -I __pycache__ --tree --depth 2'
end

if type -q yt-dlp
    function _abbr_yt
        clip_expand "yt-dlp -x --audio-format opus --audio-quality 0 '%'"
    end
    abbr --add yt --function _abbr_yt
end

if type -q wl-copy
    abbr --add Y --position anywhere "| wl-copy"
    abbr --add P "wl-paste >"
else if type -q pbcopy
    abbr --add Y --position anywhere "| pbcopy"
    abbr --add P "pbpaste >"
else if type -q xclip
    abbr --add Y --position anywhere "| xclip -selection clipboard"
    abbr --add P "xclip -selection clipboard -o >"
end

if type -q konsave
    abbr --add --set-cursor=@ ks 'konsave -e my-setup -f && mv ./my-setup.knsv "@/my-setup-$(date +%Y%m%d).knsv"'
end

# Dynamic update alias based on available package manager and devbox
set -l cmds
if type -q brew
    set cmds $cmds "brew update" "brew upgrade"
else if type -q apt-get
    set cmds $cmds "sudo apt update" "sudo apt upgrade -y"
else if type -q dnf
    set cmds $cmds "sudo dnf upgrade -y" "fwupdmgr get-updates; or true"
else if type -q cachy-update
    set cmds $cmds cachy-update
end
if not type -q cachy-update; and not type -q brew
    set cmds $cmds "flatpak update -y"
end
if type -q devbox
    set cmds $cmds " devbox global update 2>&1 | grep -v '^Info: Already up-to-date '"
end
abbr --add update (string join " && " $cmds)

abbr --add l ls
abbr --add ll ls -lg
abbr --add la ls -A
abbr --add lla ls -lgA
abbr --add lS ls -lgSA

abbr c --add cd
abbr ci --add zi
abbr g --add git
abbr gs --add git status -s
abbr gi --add git update-index --skip-worktree

abbr --add claer clear
abbr --add clr clear

abbr --add --set-cursor tc tar -czf file.tar.gz ./%
abbr --add --set-cursor tC tar -czf file.tar.gz --directory .%
abbr --add --set-cursor tx tar -xzf %.tar.gz
abbr --add --set-cursor tl tar -tf %.tar.gz

abbr --add python python3
abbr --add fk sudo kill -9
abbr --add B --position anywhere ">/dev/null 2>&1 &"
abbr --add src source

# System Specific Abbrs
set -l os (uname)
switch (uname)
    case Darwin
        abbr --add --set-cursor pkg "sudo -S installer -pkg % -target /Applications"
    case Linux
        abbr --add odlog journalctl --user-unit=onedrive -f
        abbr --add bios "systemctl reboot --firmware-setup"
end
