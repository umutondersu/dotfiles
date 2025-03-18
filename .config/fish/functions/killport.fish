function killport
    # Check if argument is provided
    if test -z "$argv"
        echo "Error: Please provide a port number"
        return 1
    end

    # Check if argument is a valid number
    if not string match -qr '^[0-9]+$' $argv[1]
        echo "Error: Port must be a valid number"
        return 1
    end

    set -l port $argv[1]
    
    # Check if port is in valid range (1-65535)
    if test $port -lt 1 -o $port -gt 65535
        echo "Error: Port must be between 1 and 65535"
        return 1
    end

    # Get process IDs using the port
    set -l pids (lsof -ti :$port)
    
    if test -z "$pids"
        echo "No processes found on port $port"
        return 1
    end

    # Kill all processes using the port
    kill $pids
    and echo "Successfully killed process(es) on port $port"
    or echo "Failed to kill some processes on port $port"
end
