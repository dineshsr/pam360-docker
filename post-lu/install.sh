#!/usr/bin/env bash

set -euxo

PMP_VERSION="$1"
PMP_TMP_HOME="/srv/PMP.orig"
PMP_INSTALLER="/tmp/pmp_installer.bin"

install_dependencies() {
  apt-get update
  apt-get install -y curl unzip

  curl -fsSL https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh \
    -o /usr/bin/wait-for-it.sh

  chmod +x /usr/bin/wait-for-it.sh
}

cleanup() {
  rm -rf \
    /var/lib/apt/lists/* \
    "${PMP_INSTALLER}" \
    /tmp/pmp.properties
}

install_pmp() {
  if [[ -e "${PMP_INSTALLER}" ]]
  then
    echo "Using the local install binary at ${PMP_INSTALLER}"
  else
    if [[ "$(dpkg --print-architecture)" == "i386" ]]
    then
      install_bin=ManageEngine_PMP.bin
    else
      install_bin=ManageEngine_PMP_64bit.bin
    fi

    url="https://archives2.manageengine.com/passwordmanagerpro/${PMP_VERSION}/${install_bin}"
    echo "Downloading PMP installer from $url"
    curl -fsSL -o "${PMP_INSTALLER}" "$url"
  fi

  chmod +x "${PMP_INSTALLER}"

  mkdir -p "$(dirname "$PMP_HOME")"
  # Update PMP_HOME in properties (/srv/pmp was used as install path at the
  # time of creation of the .properties file)
  sed -i "s|/srv/pmp|${PMP_HOME}|" /tmp/pmp.properties
  "${PMP_INSTALLER}" -i silent -f /tmp/pmp.properties
  fix_pmp_home

  cd "${PMP_HOME}/bin"  # yup. That's required by pmp.sh 🤦
  bash "${PMP_HOME}/bin/pmp.sh" install | grep "installed successfully"
}

fix_pmp_home() {
  # If PMP_HOME does not end with a PMP dir then it get installed
  # in PMP_HOME/PMP
  if [[ "$(basename "$PMP_HOME")" != "PMP" ]]
  then
    mv "${PMP_HOME}/PMP" "/tmp/pmp.tmp"
    mv "${PMP_HOME}" "/tmp/pmp_deleteme"
    rmdir "/tmp/pmp_deleteme"
    mv "/tmp/pmp.tmp" "${PMP_HOME}"
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
  echo "Building container for PMP ${PMP_VERSION}"
  install_dependencies
  install_pmp
  cleanup

  # Move PMP_HOME to PMP_HOME.orig (will be copied over to /data at runtime)
  mv "$PMP_HOME" "$PMP_TMP_HOME"
fi
