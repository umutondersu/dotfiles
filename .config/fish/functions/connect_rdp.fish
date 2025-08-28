function connect_rdp
    set -l rdp_host 127.0.0.1
    set -l rdp_port 3389

    # Wait for RDP port to be available (Docker-specific timing issue)
    echo "Waiting for RDP service to be ready..."
    while not nc -z $rdp_host $rdp_port 2>/dev/null
        echo "RDP port not ready yet, waiting 2 seconds..."
        sleep 2
    end

    echo "RDP port is ready, connecting..."
    # sleep 2 # Brief additional delay for Docker networking stability

    xfreerdp -grab-keyboard /v:$rdp_host /u:qorcialwolf /p:MyWindowsPassword /scale:180 /d: /dynamic-resolution /sound:sys:alsa /w:1920 /h:1080 /cert:tofu >/dev/null 2>&1 &
    sleep 3
    pkill -f xfreerdp
    sleep 3
    xfreerdp -grab-keyboard /v:$rdp_host /u:qorcialwolf /p:MyWindowsPassword /scale:180 /d: /dynamic-resolution /sound:sys:alsa /w:1920 /h:1080 /cert:tofu >/dev/null 2>&1 &

end
