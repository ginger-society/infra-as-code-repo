on macos


Logs: /var/log/ginger-infra.log
To stop:    sudo launchctl unload /Library/LaunchDaemons/org.gingersociety.ginger-infra.plist
To start:   sudo launchctl load /Library/LaunchDaemons/org.gingersociety.ginger-infra.plist


On linux

Logs:       sudo journalctl -u ginger-infra -f
   To stop:    sudo systemctl stop ginger-infra
   To start:   sudo systemctl start ginger-infra
   Status:     sudo systemctl status ginger-infra