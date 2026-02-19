function in
    # Usage: in /path/to/dir command args...
    set dir $argv[1]
    set cmd $argv[2..-1]
    pushd $dir >/dev/null
    command $cmd
    popd >/dev/null
end
