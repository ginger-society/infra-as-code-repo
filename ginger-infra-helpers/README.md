sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/ginger-society/infra-as-code-repo/main/ginger-infra-helpers/installer.sh)" -- --device-id my-macbook


on macos


Logs: /var/log/ginger-infra.log
To stop:    sudo launchctl unload /Library/LaunchDaemons/org.gingersociety.ginger-infra.plist
To start:   sudo launchctl load /Library/LaunchDaemons/org.gingersociety.ginger-infra.plist


On linux

Logs:       sudo journalctl -u ginger-infra -f
   To stop:    sudo systemctl stop ginger-infra
   To start:   sudo systemctl start ginger-infra
   Status:     sudo systemctl status ginger-infra



For development
--------
There is a Dockerfile that builds an image that is close to EC2 or GCP virtual machine , build it and run it 

docker build -t ubuntu-server-test . --platform=linux/amd64

docker rm -f ginger-test 2>/dev/null; docker run -d \
    --name ginger-test \
    --privileged \
    --cgroupns=host \
    -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
    -p 2222:22 \
    -p 8080:80 \
    -p 8443:443 \
    ubuntu-server-test


Log into the test image : 

docker exec -it ginger-test bash

then as a root

curl -fsSL https://raw.githubusercontent.com/ginger-society/infra-as-code-repo/main/ginger-infra-helpers/installer.sh | bash -s -- --device-id test-server-img --install-gateway


On the server as a sudoer : 

curl -fsSL https://raw.githubusercontent.com/ginger-society/infra-as-code-repo/main/ginger-infra-helpers/installer.sh | sudo bash -s -- --device-id test-server-img --install-gateway --install-k8-cluster-manager


curl -fsSL https://raw.githubusercontent.com/ginger-society/infra-as-code-repo/main/ginger-infra-helpers/installer.sh | sudo bash -s -- --device-id test-server-img