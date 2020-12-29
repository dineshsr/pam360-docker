#!/usr/bin/env bash

echo ${1}

set -euxo

PAM_VERSION="$1"
PAM_TMP_HOME="/srv/PAM.orig"
PAM_INSTALLER="/tmp/pam_installer.bin"

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
    "${PAM_INSTALLER}" \
    /tmp/pmp.properties
}

install_pam() {
  if [[ -e "${PAM_INSTALLER}" ]]
  then
    echo "Using the local install binary at ${PAM_INSTALLER}"
  else
    echo "Getting Binary from cloud"
    install_bin=ManageEngine_PAM360_64bit.bin

    url="https://archives.manageengine.com/privileged-access-management/${PAM_VERSION}/${install_bin}"
    echo "Downloading PAM360 installer from $url"
    curl -fsSL -o "${PAM_INSTALLER}" "$url"
  fi

  chmod +x "${PAM_INSTALLER}"

  mkdir -p "$(dirname "$PMP_HOME")"
  # Update PMP_HOME in properties (/srv/pmp was used as install path at the
  # time of creation of the .properties file)
  sed -i "s|/srv/pmp|${PMP_HOME}|" /tmp/pmp.properties
  "${PAM_INSTALLER}" -i silent -f /tmp/pmp.properties
  fix_pam_home

  cd "${PMP_HOME}/bin"  # yup. That's required by pmp.sh 🤦
  bash "${PMP_HOME}/bin/pam360.sh" install | grep "installed successfully"
}

fix_pam_home() {
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
  echo "Building container for PMP ${PAM_VERSION}"
  install_dependencies
  install_pam
  cleanup

  # Move PMP_HOME to PMP_HOME.orig (will be copied over to /data at runtime)
  mv "$PMP_HOME" "$PAM_TMP_HOME"
fi
