#!/usr/bin/env bash

POSTGRES_HOST=${POSTGRES_HOST:-database}
POSTGRES_PORT=${POSTGRES_PORT:-5432}
POSTGRES_DB=${POSTGRES_DB:-pmp}
POSTGRES_USER=${POSTGRES_USER:-pmp}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-pmppassword}

SERVER_STATE=${SERVER_STATE:-master}
TIMEOUT_DB=${TIMEOUT_DB:-120}
TIMEOUT_PAM=${TIMEOUT_PAM:-600}

PAM_PORT=${PAM_PORT:-8282}

sync_pmp_home_dir() {
  local PAM_TMP_HOME="/srv/PAM"
  local lockfile="${PAM_HOME}/.INIT_SYNC_DONE"

  if ! [[ -e "$lockfile" ]]
  then
    echo "Copying PAM_HOME contents to $PAM_HOME"
    if cp -a "$PAM_TMP_HOME" "$PAM_HOME"
    then
      touch "$lockfile"
    fi
  fi
}

set_server_state() {
  echo "$SERVER_STATE" > "${PAM_HOME}/conf/serverstate.conf"
}

init_conf_dir() {
  local ext_conf_path=/config
  local lockfile="${ext_conf_path}/.INIT_SYNC_DONE"

  if ! [[ -e "$lockfile" ]]
  then
    echo "Copying config files to ${ext_conf_path}."
    if cp -a "${PAM_HOME}/conf.orig/"* "$ext_conf_path"
    then
      touch "$lockfile"
    fi
  fi

  # Ensure PAM_HOME/conf is symlinked to /config
  if ! [[ -L "${PAM_HOME}/conf" ]]
  then
    ln -sf "$ext_conf_path" "${PAM_HOME}/conf"
  fi

  set_server_state
}

wait_for_db() {
  if ! wait-for-it.sh -t "$TIMEOUT_DB" "${POSTGRES_HOST}:${POSTGRES_PORT}"
  then
    echo -n "Timed out while trying to reach the database " >&2
    echo "${POSTGRES_HOST}:${POSTGRES_PORT} - Timeout: ${TIMEOUT_DB}s" >&2
    exit 8
  fi
}

install_pam_service (){

  echo "Installing service..."
  serviceName="pam360-service"
  if systemctl --all --type service | grep -q "$serviceName";
    then
      echo "$serviceName exists."
    else
      echo "$serviceName does NOT exist."
      bash "${PAM_HOME}/PAM/bin/pam360.sh" install | grep "installed successfully".
  fi
}

start_pam() {

  /home/pamuser/PAM360/PAM/bin/pam360-service start

  (tail -f "${PAM_HOME}"/PAM/logs/wrapper.log)&
}

wait_for_pam() {
  if ! wait-for-it.sh -t "$TIMEOUT_PAM" "localhost:${PAM_PORT}"
  then
    echo "PAM360 failed to start - Timeout: ${TIMEOUT_PAM}s" >&2
    exit 7
  fi
}

pam_is_running() {
  # while ps -aux | grep -q "${PAM_HOME}"
  /home/pamuser/PAM360/PAM/bin/pam360-service status | grep  "PAM360"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
  sync_pmp_home_dir

  if [[ -n "$PAM_UPGRADE" ]]
  then
    echo "!!! Started in upgrade mode." >&2
    echo "The PAM service has *NOT* been started." >&2
    echo "To disable please unset PAM_UPGRADE." >&2
    sleep infinity
  else
    # TODO Start the database
    install_pam_service
    start_pam
    wait_for_pam

    while pam_is_running
    do
      sleep 30
    done
  fi
fi
