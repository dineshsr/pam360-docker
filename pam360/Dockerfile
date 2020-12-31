ARG BASE_IMAGE=ubuntu:20.04

FROM ${BASE_IMAGE}

ENV user pamuser
ENV password Test@123

RUN useradd -m -d /home/${user} ${user} && chown -R ${user} /home/${user}

RUN usermod -aG sudo ${user}

RUN echo "${user}:${password}" | chpasswd
USER ${user}

ARG PAM_HOME=/home/${user}/PAM360
ARG PAM_VERSION=5000

ENV PAM_VERSION=$PAM_VERSION \
    PAM_HOME=$PAM_HOME \
    SERVER_STATE=master \
    TIMEOUT_DB=120 \
    TIMEOUT_PMP=600 \
    PAM_PORT=8282

WORKDIR /home/${user}

COPY pmp.properties /pmp.properties
COPY entrypoint.sh /entrypoint.sh
COPY install.sh /install.sh

RUN bash -x /install.sh "$PAM_VERSION" && rm -f /install.sh

WORKDIR ${PAM_HOME}

# https://www.manageengine.com/products/passwordmanagerpro/help/installation.html#Ports
EXPOSE 3456/tcp 8282/tcp 22/tcp 23/tcp 389/tcp 636/tcp 25/tcp 1443/tcp 1521/tcp 5000/tcp 135/tcp 139/tcp 445/tcp 6622/tcp 8283/tcp

ENTRYPOINT ["/entrypoint.sh"]

HEALTHCHECK --start-period=5m CMD curl -fqskL https://localhost:8282
