if type -q rip
    abbr --add rsd rip search deezer
    abbr --add rsdt rip search deezer track
    abbr --add rsda rip search deezer album
    abbr --add rsdu rip deezer url
end

abbr --add soundrestart systemctl --user restart wireplumber pipewire pipewire-pulse
abbr --add onedrivelog journalctl --user-unit=onedrive -f
abbr --add ga git add
abbr --add gco git checkout
abbr --add claer clear
abbr --add ltree lsd --tree --depth 2
abbr --add please sudo
abbr --add python python3
abbr --add v nvim
abbr --add V --position anywhere "&& nvim"
abbr --add ds devpod ssh
abbr --add dockersql docker run -e "'ACCEPT_EULA=Y'" -e "'MSSQL_SA_PASSWORD=password'" \
   -p 1433:1433 --name sql1 --hostname sql1 \
   -v sqlvolume:/var/opt/mssql \
   -d \
   mcr.microsoft.com/mssql/server:2022-latest
