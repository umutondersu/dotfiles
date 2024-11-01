function dct
    # Run the devcontainer command with the provided template ID and any additional arguments
    devcontainer templates apply --workspace-folder . --template-id $argv[1] $argv[2..-1]

    # Check if the devcontainer command was successful
    if test $status -eq 0
        # Call the add-runargs function only if the previous command was successful
        add-runargs
    else
        echo "devcontainer command failed, skipping add-runargs."
    end
end
