#!/usr/bin/env bash

# Copyright (c) 2021-2024 raknor90
# Author: raknor90
# https://github.com/raknor90/ProxmoxVE/raw/main/LICENSE
source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"

color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y default-jre
$STD apt-get install -y unzip
$STD apt-get install -y sudo
$STD apt-get install -y curl
$STD apt-get install -y openvpn
msg_ok "Installed Dependencies"

msg_info "Installing JDownloader"

mkdir /usr/local/JDownloader
cd /usr/local/JDownloader
wget http://installer.jdownloader.org/JDownloader.jar > /dev/null 2>&1
java -Djava.awt.headless=true -jar JDownloader.jar -norestart > /dev/null 2>&1
msg_ok "Installed JDownloader"

msg_info "Setting up MyJDownloader"
read -r -p "Enter your MyJDownloader emailadress: " email
read -r -sp "Enter your MyJDownloader password: " password
read -r -p "Enter your MyJDownloader devicename: " devicename

echo '{
  "email": "'$email'",
  "password": "'$password'",
  "devicename": "'$devicename'",
  "autoconnectenabledv2": true,
}' > ./cfg/org.jdownloader.api.myjdownloader.MyJDownloaderSettings.json

echo '{
  "freshinstall": false,
  "enabled": true
}' > ./cfg/org.jdownloader.extensions.eventscripter.EventScripterExtension.json

echo '[
  {
    "eventTrigger": "INTERVAL",
    "enabled": true,
    "name": "Auto-update",
    "script": "disablePermissionChecks(); if (callAPI('update', 'isUpdateAvailable') && isDownloadControllerIdle() && !callAPI('linkcrawler', 'isCrawling') && !callAPI('linkgrabberv2', 'isCollecting') && !callAPI('extraction', 'getQueue').length > 0) { callAPI('update', 'restartAndUpdate'); }",
    "eventTriggerSettings": {
      "lastFire": 1594799412187,
      "interval": 43200000,
      "isSynchronous": false
    },
    "id": 1594796988140
  }
]' > ./cfg/org.jdownloader.extensions.eventscripter.EventScripterExtension.scripts.json

echo '{
  "defaultdownloadfolder": "/mnt/Downloads"
}' > ./cfg/org.jdownloader.settings.GeneralSettings.json

echo '[
  "eventscripter"
]' > ./update/versioninfo/JD/extensions.requestedinstalls.json

java -jar JDownloader.jar > log.txt 2>&1 &
msg_ok "Setting set for MyJDownloader"

msg_info "Installing NordVPN"
cd
script='#!/bin/bash\
mkdir -p /dev/net
mknod /dev/net/tun c 10 200
chmod 600 /dev/net/tun

/etc/init.d/openvpn restart'
echo -e $script > OpenVPNfix.sh
chmod 775 OpenVPNfix.sh
cd /etc/openvpn
wget https://downloads.nordcdn.com/configs/archives/servers/ovpn.zip
unzip ovpn.zip
rm ovpn.zip

read -r -p "Enter your NordVPN username: " NordVPNusername
read -r -sp "Enter your NordVPN password: " NordVPNpassword

script="$NordVPNusername\n$NordVPNpassword"
echo -e $script > /etc/openvpn/pass.txt

msg_ok "Installed NordVPN"

msg_info "Installing Filebot"
# curl -fsSL https://raw.githubusercontent.com/filebot/plugins/master/installer/deb.sh | sh -xu
msg_ok "Installed Filebot"

msg_info "Configure Autostart"

cat > /etc/systemd/system/jdvpn.service <<EOL
[Unit]
Description=jdvpn Service
After=network.target

[Service]
Type=simple
ExecStart=openvpn --config /etc/openvpn/ovpn_tcp/us8519.nordvpn.com.tcp.ovpn --auth-user-pass /etc/openvpn/pass.txt
RemainAfterExit=no

User=root
Group=root

[Install]
RequiredBy=jdownloader.service
EOL

cat > /etc/systemd/system/jdownloader.service <<EOL
[Unit]
Description=JDownloader Service
After=jdvpn.service
Requires=jdvpn.service


[Service]
Environment=JD_HOME=/usr/local/JDownloader
Type=simple
ExecStart=java -jar /usr/local/JDownloader/JDownloader.jar
PIDFile=/usr/local/JDownloader/JDownloader.pid
RemainAfterExit=yes

User=root
Group=root

[Install]
WantedBy=multi-user.target
EOL
systemctl enable jdownloader.service
systemctl start jdownloader.service

msg_ok "AutoStart configured"

motd_ssh
customize


msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"


# read -r -p "Would you like to add Portainer? <y/N> " prompt
# if [[ ${prompt,,} =~ ^(y|yes)$ ]]; then
#   msg_info "Installing Portainer $PORTAINER_LATEST_VERSION"
#   docker volume create portainer_data >/dev/null
#   $STD docker run -d \
#     -p 8000:8000 \
#     -p 9443:9443 \
#     --name=portainer \
#     --restart=always \
#     -v /var/run/docker.sock:/var/run/docker.sock \
#     -v portainer_data:/data \
#     portainer/portainer-ce:latest
#   msg_ok "Installed Portainer $PORTAINER_LATEST_VERSION"
# else
#   read -r -p "Would you like to add the Portainer Agent? <y/N> " prompt
#   if [[ ${prompt,,} =~ ^(y|yes)$ ]]; then
#     msg_info "Installing Portainer agent $PORTAINER_AGENT_LATEST_VERSION"
#     $STD docker run -d \
#       -p 9001:9001 \
#       --name portainer_agent \
#       --restart=always \
#       -v /var/run/docker.sock:/var/run/docker.sock \
#       -v /var/lib/docker/volumes:/var/lib/docker/volumes \
#       portainer/agent
#     msg_ok "Installed Portainer Agent $PORTAINER_AGENT_LATEST_VERSION"
#   fi
# fi
# read -r -p "Would you like to add Docker Compose? <y/N> " prompt
# if [[ ${prompt,,} =~ ^(y|yes)$ ]]; then
#   msg_info "Installing Docker Compose $DOCKER_COMPOSE_LATEST_VERSION"
#   DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
#   mkdir -p $DOCKER_CONFIG/cli-plugins
#   curl -sSL https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_LATEST_VERSION/docker-compose-linux-x86_64 -o ~/.docker/cli-plugins/docker-compose
#   chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
#   msg_ok "Installed Docker Compose $DOCKER_COMPOSE_LATEST_VERSION"
# fi
