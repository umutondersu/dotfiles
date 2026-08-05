function load_env_vars -d "Load variables in a .env file"
    if test (count $argv) -eq 0; or not test -f $argv[1]
        return
    end
    set lines (cat $argv[1] | string split -n '\n' | string match -vre '^#')
    for line in $lines
        set arr (string split -n -m 1 = $line)
        if test (count $arr) -ne 2
            continue
        end
        set -gx $arr[1] $arr[2]
    end
end
