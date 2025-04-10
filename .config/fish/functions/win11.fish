function win11
    # Check if win11-base is already running
    if virsh --connect qemu:///system list --name --state-running | grep -q '^win11-base$'
        echo "win11-base is already running."
    else
        echo "Starting win11-base..."
        virsh --connect qemu:///system start win11-base
        sleep 30
    end

    # Execute xfreerdp command
    xfreerdp -grab-keyboard /v:192.168.122.29 /u:qorcialwolf /p:susam123 /size:100% /d: /dynamic-resolution +gfx-progressive
end
