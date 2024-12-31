function mkfile
    if test -z "$argv"
        echo "create a file and optionally its parent dir(s) if they don't exist"
        echo "usage: "
        echo "  mkfile path/to/file"
        return
    end

    # why use mkdir -p + touch when I can do it all in one command!
    set -l path $argv
    set -l parent (dirname $path)
    mkdir -p $parent
    touch $path
    # PRN handle case where mkfile has a / on end and make it behave like mkdir -p in that case? (not create the file)... not really a primary use case for the touch command other than I could write a unified command to create a dir or a file
end
