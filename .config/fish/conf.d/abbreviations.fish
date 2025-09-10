if type -q rip
    abbr --add --set-cursor rs "rip search deezer '%'"
    abbr --add --set-cursor rst "rip search deezer track '%'"
    abbr --add --set-cursor rsa "rip search deezer album '%'"
    abbr --add --set-cursor rsu "rip search deezer url '%'"
end

if type -q devpod
    abbr --add dp devpod
    abbr --add dps devpod ssh
    abbr --add dpu devpod up .
    abbr --add dpd devpod delete
    abbr --add dpS devpod stop
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

if type -q lsd
    abbr --add lT ls --tree --depth 2
    abbr --add lt 'ls -I node_modules -I dist -I build -I .idea -I .vscode -I target -I out -I .pytest_cache -I .cache -I tmp -I __pycache__ --tree --depth 2'
end
abbr --add l ls
abbr --add ll ls -lg
abbr --add la ls -A
abbr --add lla ls -lgA
abbr --add lS ls -lgSA

abbr c --add cd
abbr g --add git

abbr --add onedrivelog journalctl --user-unit=onedrive -f
abbr --add claer clear
abbr --add clr clear
abbr --add python python3
abbr --add fkill sudo kill -9
abbr --add Y --position anywhere "| xclip -selection clipboard"
abbr --add P "xclip -selection clipboard -o >"
abbr --add B --position anywhere ">/dev/null &"
abbr --add update 'sudo apt update && sudo apt upgrade -y && flatpak update -y'
abbr --add --set-cursor tzip tar -czvf %.tar.gz ./
abbr --add --set-cursor tuzip tar -xzf %.tar.gz
abbr --add src source

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
        -e POSTGRES_PASSWORD=password \
        postgres
    abbr --add mysqld docker run -d \
        --name mysql-container \
        -e MYSQL_ROOT_PASSWORD=your_password \
        -p 3306:3306 \
        mysql:latest
end
