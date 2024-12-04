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
  NET=""
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

if NEWTOKEN=$(whiptail --backtitle "Proxmox VE Helper Scripts" --passwordbox "Set the ADMIN_TOKEN" 10 58 3>&1 1>&2 2>&3); then
  if [[ -z "$NEWTOKEN" ]]; then exit; fi
  if ! command -v argon2 >/dev/null 2>&1; then apt-get install -y argon2 &>/dev/null; fi
  TOKEN=$(echo -n ${NEWTOKEN} | argon2 "$(openssl rand -base64 32)" -t 2 -m 16 -p 4 -l 64 -e)
  sed -i "s|ADMIN_TOKEN=.*|ADMIN_TOKEN='${TOKEN}'|" /opt/vaultwarden/.env
  if [[ -f /opt/vaultwarden/data/config.json ]]; then
    sed -i "s|\"admin_token\":.*|\"admin_token\": \"${TOKEN}\"|" /opt/vaultwarden/data/config.json
  fi
  systemctl restart vaultwarden
fi

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

msg_ok "Completed Successfully!\n"
