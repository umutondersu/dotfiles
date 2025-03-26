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
   abbr --add dpS devpod stop
end

abbr --add soundrestart systemctl --user restart wireplumber pipewire pipewire-pulse
abbr --add onedrivelog journalctl --user-unit=onedrive -f
abbr --add claer clear
abbr --add lst lsd --tree --depth 2
abbr --add python python3
abbr --add v nvim
abbr --add V --position anywhere "&& nvim"
abbr --add fkill sudo kill -9

# Abbreviations for starting up servers with docker
if type -q docker
   #open-webui
   abbr --add open_webuid docker run -d \
               --name open-webui \
               -p 3001:8080 \
               -e WEBUI_AUTH=False \
               -v open-webui:/app/backend/data \
               --restart unless-stopped \
               --add-host host.docker.internal:host-gateway \
               ghcr.io/open-webui/open-webui:mai

   #SQL
   abbr --add mssqld docker run -p 1433:1433 --name mssql --hostname mssql \
      -d \
      mcr.microsoft.com/mssql/server:2022-latest \
      -v sqlvolume:/var/opt/mssql \
      -e "'ACCEPT_EULA=Y'" -e "'MSSQL_SA_PASSWORD=password'"

   abbr --add psqld docker run -d \
      -p 5432:5432 \
      --name postgres \
      -v pgdata:/var/lib/postgresql/data \
      -e POSTGRES_PASSWORD=password  \
      postgres \

   abbr --add mysqld docker run -d \
      --name mysql-container \
      -e MYSQL_ROOT_PASSWORD=your_password \
      -p 3306:3306 \
      mysql:latest
end
