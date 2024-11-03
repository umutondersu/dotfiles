function dcconfig
    # Find the devcontainer.json file in the current directory or subdirectories
    set json_file (find . -name "devcontainer.json" -print -quit)

    # Check if the file was found
    if test -n "$json_file"
        # Check if runArgs already exists in the devcontainer.json
        set existing (grep -c '"runArgs":' $json_file)

        if test $existing -eq 0
            # If runArgs does not exist, add it
            sed -i -e '/"image":/s|"$|",|' \
                -e '/"image":/a\
\
    "features": {\
        "ghcr.io/duduribeiro/devcontainer-features/neovim:1": {\
        "version": "stable"\
        }\
  },\
\
    "runArgs": [\
        "--env", "DISPLAY",\
        "--env", "XAUTHORITY=/tmp/.docker.xauth",\
        "--volume", "/tmp/.X11-unix:/tmp/.X11-unix",\
        "--volume", "${localEnv:HOME}/.Xauthority:/tmp/.docker.xauth"\
    ]' $json_file
        else
            echo "runArgs already exists, skipping addition."
        end
    else
        echo "Error: devcontainer.json not found in the current directory or subdirectories."
    end
end
