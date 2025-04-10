function win11
    # Check if VM is running
    if virsh --connect qemu:///system list --name --state-running | grep -q '^win11-base$'
        echo "Shutting down Windows 11 VM..."
        virsh --connect qemu:///system shutdown win11-base
        
        # Wait for VM to shutdown (timeout after 30 seconds)
        for i in (seq 30)
            if not virsh --connect qemu:///system list --name --state-running | grep -q '^win11-base$'
                echo "VM shutdown completed."
                return
            end
            sleep 1
        end
        
        # Force shutdown if normal shutdown fails
        if virsh --connect qemu:///system list --name --state-running | grep -q '^win11-base$'
            echo "VM did not shutdown gracefully. Forcing shutdown..."
            virsh --connect qemu:///system destroy win11-base
        end
    else
        echo "Starting Windows 11 VM..."
        virsh --connect qemu:///system start win11-base
        
        # Start the RDP connection in true background
        fish -c "sleep 30; source ~/.config/fish/functions/connect_rdp.fish; connect_rdp" &
        
        echo "VM startup initiated - RDP will connect automatically in 30 seconds"
    end
end
