if type -q rip
    abbr --add rsd rip search deezer
    abbr --add rsdt rip search deezer track
    abbr --add rsda rip search deezer album
    abbr --add rsdu rip deezer url
end

if type -q devpod
   abbr --add dp devpod
   abbr --add dps devpod ssh
   abbr --add dpu devpod up .
   abbr --add dpd devpod delete
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
abbr kp sudo kill -9

# Abbreviations for starting up sql servers
abbr --add dmssql docker run -p 1433:1433 --name mssql --hostname mssql \
   -d \
   mcr.microsoft.com/mssql/server:2022-latest \
   -v sqlvolume:/var/opt/mssql \
   -e "'ACCEPT_EULA=Y'" -e "'MSSQL_SA_PASSWORD=password'"

abbr --add dpgsql docker run -p 5432:5432 \
   -d \
   postgres \
   --name postgres \
   -v pgdata:/var/lib/postgresql/data \
   -e "'POSTGRES_USER=postgres'" -e "'POSTGRES_PASSWORD=password'"  \
