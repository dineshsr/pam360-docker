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
  local PAM_TMP_HOME="/srv/PMP.orig"
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

start_pam() {
  /etc/init.d/pam360-service start

  (tail -f "${PAM_HOME}"/logs/*)&
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
  /etc/init.d/pam360-service status | grep -q "PAM360 is running"
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
    start_pam
    wait_for_pam

    while pam_is_running
    do
      sleep 5
    done
  fi
fi
