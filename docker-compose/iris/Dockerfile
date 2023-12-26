# syntax=docker/dockerfile:1.6

FROM containers.intersystems.com/intersystems/iris:2023.2.0.221.0

ENV PIP_REQUESTS_VERSION=2.31.0 \
    PIP_GOOGLE_CLOUD_COMPUTE_VERSION=1.15.0 \
    GCLOUD_CLI_VERSION=458.0.1-0

USER root

COPY set_alias_ip.py /usr/irissys/lib/python/set_alias_ip.py
COPY ZMIRROR.mac /tmp/ZMIRROR.mac
COPY iris.script /tmp/iris.script

RUN pip3 install \
        Requests==${PIP_REQUESTS_VERSION} \
        google-cloud-compute==${PIP_GOOGLE_CLOUD_COMPUTE_VERSION} \
    # Make Alias IP Python script executable
    && chmod +x /usr/irissys/lib/python/set_alias_ip.py \
    # Install gcloud
    && apt-get update \
    && apt-get install -y \
        apt-transport-https \
        ca-certificates \
        gnupg \
        curl \
    && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
    && apt-get update \
    && apt-get install -y google-cloud-cli=${GCLOUD_CLI_VERSION} \
    && rm -rf /var/lib/apt/lists/*

# User irisowner
USER ${ISC_PACKAGE_MGRUSER}

# Import ZMIRROR routine
# RUN --mount=type=secret,id=./iris.key,dst=/usr/irissys/mgr/iris.key,uid=51773,mode=0640,required=true \

RUN iris start ${ISC_PACKAGE_INSTANCENAME} quietly \
    && iris session ${ISC_PACKAGE_INSTANCENAME} < /tmp/iris.script \
    && iris stop ${ISC_PACKAGE_INSTANCENAME} quietly
