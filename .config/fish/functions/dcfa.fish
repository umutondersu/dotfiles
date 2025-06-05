function dcfa
    # Use dctemplates with fzf to select a feature
    set selected_feature (dctemplates | fzf)

    # Check if a feature was selected
    if test -n "$selected_feature"
        # Format the selected feature
        set formatted_feature "\t\"$selected_feature\": {},"

        # Find the devcontainer.json file in the current directory or subdirectories
        set json_file (find . -name "devcontainer.json" -print -quit)

        if test -z "$json_file"
            echo "Error: devcontainer.json not found in the current directory or subdirectories."
            return 1
        end

        # Delete any commented lines that look like // "features": {},
        sed -i '/\/\/ "features": {},/d' $json_file

        # Check if features exists in the devcontainer.json
        set existing (grep -c '"features": {' $json_file)
        if test $existing -eq 0
            echo "No features section found in devcontainer.json"
            return 1
        end

        # Insert the formatted feature below the "features": { line
        sed -i -e "/\"features\": {/a\\$formatted_feature" $json_file
        echo "Feature added to devcontainer.json"

    else
        echo "No feature selected."
    end
end
