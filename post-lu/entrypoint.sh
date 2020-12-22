#!/usr/bin/env bash

POSTGRES_HOST=${POSTGRES_HOST:-database}
POSTGRES_PORT=${POSTGRES_PORT:-5432}
POSTGRES_DB=${POSTGRES_DB:-pmp}
POSTGRES_USER=${POSTGRES_USER:-pmp}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-pmppassword}

SERVER_STATE=${SERVER_STATE:-master}
TIMEOUT_DB=${TIMEOUT_DB:-60}
TIMEOUT_PMP=${TIMEOUT_PMP:-300}

PMP_PORT=${PMP_PORT:-7272}

sync_pmp_home_dir() {
  local PMP_TMP_HOME="/srv/PMP.orig"
  local lockfile="${PMP_HOME}/.INIT_SYNC_DONE"

  if ! [[ -e "$lockfile" ]]
  then
    echo "Copying PMP_HOME contents to $PMP_HOME"
    if cp -a "$PMP_TMP_HOME" "$PMP_HOME"
    then
      touch "$lockfile"
    fi
  fi
}

set_server_state() {
  echo "$SERVER_STATE" > "${PMP_HOME}/conf/serverstate.conf"
}

init_conf_dir() {
  local ext_conf_path=/config
  local lockfile="${ext_conf_path}/.INIT_SYNC_DONE"

  if ! [[ -e "$lockfile" ]]
  then
    echo "Copying config files to ${ext_conf_path}."
    if cp -a "${PMP_HOME}/conf.orig/"* "$ext_conf_path"
    then
      touch "$lockfile"
    fi
  fi

  # Ensure PMP_HOME/conf is symlinked to /config
  if ! [[ -L "${PMP_HOME}/conf" ]]
  then
    ln -sf "$ext_conf_path" "${PMP_HOME}/conf"
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

start_pmp() {
  /etc/init.d/pmp-service start

  (tail -f "${PMP_HOME}"/logs/*)&
}

wait_for_pmp() {
  if ! wait-for-it.sh -t "$TIMEOUT_PMP" "localhost:${PMP_PORT}"
  then
    echo "PMP failed to start - Timeout: ${TIMEOUT_PMP}s" >&2
    exit 7
  fi
}

pmp_is_running() {
  # while ps -aux | grep -q "${PMP_HOME}"
  /etc/init.d/pmp-service status | grep -q "PMP is running"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
  sync_pmp_home_dir

  if [[ -n "$PMP_UPGRADE" ]]
  then
    echo "!!! Started in upgrade mode." >&2
    echo "The PMP service has *NOT* been started." >&2
    echo "To disable please unset PMP_UPGRADE." >&2
    sleep infinity
  else
    # TODO Start the database
    start_pmp
    wait_for_pmp

    while pmp_is_running
    do
      sleep 5
    done
  fi
fi
