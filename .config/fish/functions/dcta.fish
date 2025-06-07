function dcta
    set json_file (find . -name "devcontainer.json" -print -quit)
    # Check if devcontainer.json exists if so end the function
    if test -n "$json_file"
        echo "devcontainer.json already exists in this project, aborting devcontainer creation"
        return 1
    end

    set template (dctemplates | fzf) # or `peco` if you have it installed

    if test -n "$template"
        echo "Applying dev container template: $template"
        # Replace with your actual dev container command
        devcontainer templates apply --workspace-folder . --template-id $template $argv
    else
        echo "No template selected."
    end

    # Check if the devcontainer command was successful
    if test $status -eq 0
        # Call the config function to automatically add necessary keys to the devcontainer.json
        dcconfig
    else
        echo "devcontainer command failed, skipping dcconfig"
    end
end
