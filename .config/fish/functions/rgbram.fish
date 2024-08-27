function rgbram
    # Check if the correct number of arguments is provided
    if test (count $argv) -ne 3
        echo "Usage: rgbram <R> <G> <B>"
        return 1
    end

    # Define the path to rgbram.sh
    set script_path /home/qorcialwolf/.startup/rgbram.sh

    # Check if rgbram.sh exists
    if not test -f "$script_path"
        echo "rgbram.sh not found at $script_path"
        return 1
    end

    # Execute rgbram.sh with the provided arguments
    sudo $script_path $argv[1] $argv[2] $argv[3]
end

