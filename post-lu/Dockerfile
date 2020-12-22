ARG BASE_IMAGE=ubuntu:20.04

FROM ${BASE_IMAGE}

ARG PMP_HOME=/data/PMP
ARG PMP_VERSION=10404

ENV PMP_VERSION=$PMP_VERSION \
    PMP_HOME=$PMP_HOME \
    SERVER_STATE=master \
    TIMEOUT_DB=60 \
    TIMEOUT_PMP=300 \
    PMP_PORT=7272

COPY pmp.properties /tmp/pmp.properties
COPY entrypoint.sh /entrypoint.sh
COPY install.sh /install.sh

RUN bash -x /install.sh "$PMP_VERSION" && rm -f /install.sh

WORKDIR ${PMP_HOME}

# https://www.manageengine.com/products/passwordmanagerpro/help/installation.html#Ports
EXPOSE 2345/tcp 5522/tcp 7070/tcp 7272/tcp 7273/tcp

ENTRYPOINT ["/entrypoint.sh"]

VOLUME ["/data"]

HEALTHCHECK --start-period=5m CMD curl -fqskL https://localhost:7272
