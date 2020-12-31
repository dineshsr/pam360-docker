#!/usr/bin/env bash

set -euxo

PAM_VERSION="$1"
PAM_TMP_HOME="/srv/PAM"
PAM_INSTALLER="/tmp/pam_installer.bin"

install_dependencies() {
  apt-get update
  apt-get install -y curl install iputils-ping sudo nano unzip

  curl -fsSL https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh \
    -o /usr/bin/wait-for-it.sh

  chmod +x /usr/bin/wait-for-it.sh
}

add_and_elivate_user(){

  useradd -m -d /home/${USER} ${USER} && chown -R ${USER} /home/${USER}

  usermod -aG sudo ${USER}

  echo "${USER}:${PASSWORD}" | chpasswd
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
    install_bin=ManageEngine_PAM360_64bit.bin

    url="https://archives.manageengine.com/privileged-access-management/${PAM_VERSION}/${install_bin}"
    echo "Downloading PAM360 installer from $url"
    curl -fsSL -o "${PAM_INSTALLER}" "$url"
  fi

  chmod +x "${PAM_INSTALLER}"

  mkdir -p "$(dirname "$PAM_HOME")"
  # Update PAM_HOME in properties (/srv/pmp was used as install path at the
  # time of creation of the .properties file)
  sed -i "s|/srv/pam|${PAM_HOME}|" /tmp/pmp.properties
  "${PAM_INSTALLER}" -i silent -f /tmp/pmp.properties
  fix_pmp_home

  cd "${PAM_HOME}"

  cd "bin"  # yup. That's required by pmp.sh 🤦
  bash "${PAM_HOME}/bin/pam360.sh" install | grep "installed successfully"
}

fix_pmp_home() {
  # If PAM_HOME does not end with a PMP dir then it get installed
  # in PAM_HOME/PMP
  if [[ "$(basename "$PAM_HOME")" != "PAM360" ]]
  then
    mv "${PAM_HOME}/PAM360" "/tmp/pmp.tmp"
    mv "${PAM_HOME}" "/tmp/pmp_deleteme"
    rmdir "/tmp/pmp_deleteme"
    mv "/tmp/pmp.tmp" "${PAM_HOME}"
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
  echo "Building container for PMP ${PAM_VERSION}"
  install_dependencies
  add_and_elivate_user
  install_pam
  cleanup

  # Move PAM_HOME to PAM_HOME.orig (will be copied over to /data at runtime)
  mv "$PAM_HOME" "$PAM_TMP_HOME"
fi
