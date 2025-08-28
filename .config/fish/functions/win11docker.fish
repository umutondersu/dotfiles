function win11docker
    # Check if container is running
    if docker ps | grep -q WinApps
        echo "Shutting down Windows 11 container..."
        docker stop WinApps

        # Wait for container to shutdown (timeout after 30 seconds)
        # @fish-lsp-disable-next-line 4004
        for i in (seq 30)
            if not docker ps | grep -q WinApps
                echo "Container shutdown completed."
                return
            end
            sleep 1
        end
        # force shutdown if normal shutdown fails
        if docker ps | grep -q WinApps
            echo "container did not shutdown gracefully. forcing shutdown..."
            docker kill winapps
        end
    else
        echo "Starting Windows 11 container..."
        docker compose --file ~/.config/winapps/compose.yaml up -d

        # Start the RDP connection in true background
        fish -c "sleep 10; source ~/.config/fish/functions/connect_rdp.fish; connect_rdp" &

        echo "Container startup initiated - RDP will connect automatically in 10 seconds"
    end
end
