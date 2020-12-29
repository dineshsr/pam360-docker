ARG BASE_IMAGE=ubuntu:20.04

FROM ${BASE_IMAGE}

ARG PAM_HOME=/data/PAM360
ARG PAM_VERSION=5000

ENV PAM_VERSION=$PAM_VERSION \
    PAM_HOME=$PAM_HOME \
    SERVER_STATE=master \
    TIMEOUT_DB=120 \
    TIMEOUT_PMP=600 \
    PAM_PORT=8282

COPY pmp.properties /tmp/pmp.properties
COPY pam_installer.bin /tmp/pam_installer.bin
COPY entrypoint.sh /entrypoint.sh
COPY install.sh /install.sh

RUN bash -x /install.sh "$PAM_VERSION" && rm -f /install.sh

WORKDIR ${PAM_HOME}

# https://www.manageengine.com/products/passwordmanagerpro/help/installation.html#Ports
EXPOSE 3456/tcp 8282/tcp 22/tcp 23/tcp 389/tcp 636/tcp 25/tcp 1443/tcp 1521/tcp 5000/tcp 135/tcp 139/tcp 445/tcp 6622/tcp 8283/tcp

ENTRYPOINT ["/entrypoint.sh"]

VOLUME ["/data"]

HEALTHCHECK --start-period=5m CMD curl -fqskL https://localhost:8282
