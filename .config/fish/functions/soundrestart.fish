function soundrestart
    echo "Restarting sound system..."

    # Find and kill EasyEffects process
    if set -l pid (pgrep easyeffects)
        kill $pid
        sleep 2 # Wait for EasyEffects to fully close
        echo "EasyEffects stopped"
    end

    # Restart sound system services
    echo "Restarting PipeWire services..."
    if not systemctl --user restart wireplumber pipewire pipewire-pulse
        echo "Error: Failed to restart sound services"
        return 1
    end

    # Wait longer for services to stabilize
    echo "Waiting for services to stabilize..."
    sleep 5

    # Check if services are running
    if systemctl --user is-active pipewire >/dev/null
        echo "Sound services restarted successfully"
        echo "Starting EasyEffects..."
        flatpak run com.github.wwmm.easyeffects --gapplication-service >/dev/null 2>&1 &
        disown
    else
        echo "Error: PipeWire service failed to start"
        return 1
    end
end
