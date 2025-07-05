FROM ubuntu:jammy-20250619

ARG VSTS_VERSION=4.258.1

ARG ENVIRONMENT_TYPE=AzureDevops

WORKDIR /opt/vstsagent 

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
	curl \
	jq \
	unzip \
	libicu-dev \
	ca-certificates \
	git \
	&& update-ca-certificates \
	&& curl -sL https://aka.ms/InstallAzureCLIDeb | bash \
	&& curl -fSsL -O https://download.agent.dev.azure.com/agent/4.258.1/vsts-agent-linux-x64-4.258.1.tar.gz \
	&& tar -xvf vsts-agent-linux-x64-4.258.1.tar.gz \
	&& rm -rf vsts-agent-linux-x64-4.258.1.tar.gz \
	&& apt autoremove \
	&& rm -rf /var/lib/apt/lists/*

RUN useradd -m vstsagent \
    && chown -R vstsagent:vstsagent /opt/vstsagent

COPY --chown=vstsagent:vstsagent script.sh shutdown.sh /opt/vstsagent/

RUN chmod +x /opt/vstsagent/*.sh

USER vstsagent

CMD ["/opt/vstsagent/script.sh"]