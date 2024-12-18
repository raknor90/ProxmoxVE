#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/raknor90/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 raknor90
# Author: raknor90
# https://github.com/raknor90/ProxmoxVE/raw/main/LICENSE

# App Default Values
APP="JDownloader"
var_tags="jdownloader;debian"
var_disk="2"
var_cpu="2"
var_ram="512"
var_os="debian"
var_version="12"
var_unprivileged="1"

# App Output & Base Settings
header_info "$APP"
base_settings

variables
color
catch_errors


function update_script() {
header_info
check_container_storage
check_container_resources

if [[ ! -d /var ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
msg_info "Updating ${APP} LXC"
apt-get update &>/dev/null
apt-get -y upgrade &>/dev/null
msg_ok "Updated ${APP} LXC"
exit
}


start
build_container
description

echo "lxc.cgroup2.devices.allow: c 10:200 rwm" >> "/etc/pve/lxc/$NEXTID.conf"
echo "lxc.mount.entry: /dev/net dev/net none bind,create=dir" >> "/etc/pve/lxc/$NEXTID.conf"
chown 100000:100000 /dev/net/tun
ls -l /dev/net/tun

msg_info "Mount download dir from cifs share"
echo ''
read -p  "    Enter the folder name (e.g., nas_rwx): " folder_name
read -p  "    Enter the CIFS hostname or IP (e.g., NAS): " cifs_host
read -p  "    Enter the share name (e.g., media): " share_name
read -p  "    Enter SMB username: " smb_username
read -sp "    Enter SMB password: " smb_password && echo
# read -p "Enter the LXC ID: " lxc_id
read -p "    Enter the username within the LXC that needs access to the share (e.g., jellyfin, plex): " lxc_username

bash -c "$(wget -qO - https://gist.githubusercontent.com/NorkzYT/14449b247dae9ac81ba4664564669299/raw/7d2d0fce37a8896823c9035a2e765d14a96058c0/proxmox-lxc-cifs-share.sh)" << ANSWER
$folder_name
$cifs_host
$share_name
$smb_username
$smb_password
$NEXTID
$lxc_username
ANSWER
msg_ok "Mounted download dir from cifs share "
msg_ok "Completed Successfully!\n"



