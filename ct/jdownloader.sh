#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/raknor90/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/raknor90/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
       ______                      __                __         
      / / __ \____ _      ______  / /___  ____ _____/ /__  _____
 __  / / / / / __ \ | /| / / __ \/ / __ \/ __ `/ __  / _ \/ ___/
/ /_/ / /_/ / /_/ / |/ |/ / / / / / /_/ / /_/ / /_/ /  __/ /    
\____/_____/\____/|__/|__/_/ /_/_/\____/\__,_/\__,_/\___/_/     

EOF
}
header_info
echo -e "Loading..."
APP="JDownloader"
var_disk="2"
var_cpu="2"
var_ram="512"
var_os="alpine"
var_version="3.19"


variables
color
catch_errors

function default_settings() {
  CT_TYPE="1"
  PW=""
  CT_ID=$NEXTID
  HN=$NSAPP
  DISK_SIZE="$var_disk"
  CORE_COUNT="$var_cpu"
  RAM_SIZE="$var_ram"
  BRG="vmbr0"
  NET="dhcp"
  GATE=""
  APT_CACHER=""
  APT_CACHER_IP=""
  DISABLEIP6="no"
  MTU=""
  SD=""
  NS=""
  MAC=""
  VLAN=""
  SSH="no"
  VERB="no"
  echo_default
}

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
