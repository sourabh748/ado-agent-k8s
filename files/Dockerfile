FROM ubuntu:jammy-20250619 AS vstsbuild

WORKDIR /opt/vstsagent

RUN apt-get update && apt-get install -y curl \
    && curl -fSsL -O https://download.agent.dev.azure.com/agent/4.258.1/vsts-agent-linux-x64-4.258.1.tar.gz \
    && tar -xvf vsts-agent-linux-x64-4.258.1.tar.gz && rm -rf vsts-agent-linux-x64-4.258.1.tar.gz

FROM mcr.microsoft.com/openjdk/jdk:17-ubuntu

WORKDIR /opt/vstsagent

RUN useradd -m vstsagent

COPY --from=vstsbuild --chown=vstsagent:vstsagent /opt/vstsagent/ .

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    unzip \
    libicu-dev \
    git \
    && rm -rf /var/lib/apt/lists/* \
    rm /packages-microsoft-prod.deb \
    && curl -sL https://aka.ms/InstallAzureCLIDeb | bash \
    && update-ca-certificates

COPY --chown=vstsagent:vstsagent script.sh shutdown.sh /opt/vstsagent/

RUN chmod +x /opt/vstsagent/*.sh \
    && chown -R vstsagent:vstsagent /opt/vstsagent

USER vstsagent

CMD ["/opt/vstsagent/script.sh"]