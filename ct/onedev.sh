#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/raknor90/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 community-scripts ORG
# Author: kristocopani
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://onedev.io/

# App Default Values
APP="OneDev"
var_tags="git"
var_cpu="2"
var_ram="2048"
var_disk="4"
var_os="debian"
var_version="12"
var_unprivileged="1"

# App Output & Base Settings
header_info "$APP"
base_settings

# Core
variables
color
catch_errors
function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -f /etc/systemd/system/onedev.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  GITHUB_RELEASE=$(curl -s https://api.github.com/repos/theonedev/onedev/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${GITHUB_RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Stopping Service"
    systemctl stop onedev
    msg_ok "Stopped Service"

    msg_info "Updating ${APP} to v${GITHUB_RELEASE}"
    cd /opt
    wget -q https://code.onedev.io/onedev/server/~site/onedev-latest.tar.gz
    tar -xzf onedev-latest.tar.gz
    /opt/onedev-latest/bin/upgrade.sh /opt/onedev >/dev/null
    RELEASE=$(cat /opt/onedev/release.properties | grep "version" | cut -d'=' -f2)
    echo "${RELEASE}" >"/opt/${APP}_version.txt"
    msg_ok "Updated ${APP} to v${RELEASE}"

    msg_info "Starting Service"
    systemctl start onedev
    msg_ok "Started Service"

    msg_info "Cleaning up"
    rm -rf /opt/onedev-latest
    rm -rf /opt/onedev-latest.tar.gz
    msg_ok "Cleaned"
    msg_ok "Updated Successfully"
  else
    msg_ok "No update required. ${APP} is already at v${RELEASE}."
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:6610${CL}"