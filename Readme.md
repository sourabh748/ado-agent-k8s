# Custom Azure DevOps Agent Docker Image

This Docker image provides a pre-configured Azure DevOps agent (VSTS agent) based on Ubuntu Jammy (22.0) and mcr.microsoft.com/openjdk/jdk:17-ubuntu, tailored for environments behind a proxy and with retry logic for agent configuration.

---

## 🐳 Image Overview ( this docs provides image with two distinct tags `mcr-jdk-20250705`, `ubuntu-jammy-20250619` )

- **Base Image:** 
    1. `ubuntu:jammy-20250619`, [Dockerfile](./Dockerfile)
    2. `mcr.microsoft.com/openjdk/jdk:17-ubuntu` [Dockerfile](./files/Dockerfile)
- **Azure DevOps Agent Version:** `4.258.1`
- **Features:**
  - Supports running behind HTTP/HTTPS proxy
  - Configurable via environment variables
  - Retries configuration on failure
  - Graceful shutdown and cleanup
  - Runs Azure CLI out-of-the-box

- **Docker Hub link**
    - Image with java [👉 click ](https://hub.docker.com/repository/docker/spidocker4/vstsagent/tags/mcr-jdk-20250705/sha256-c0cbf29d5085a64e14b7b3b5d739f6e8ab06ecd697973d3c2dc2ac196452deeb)
    - Plain VSTS agent  [👉 click ](https://hub.docker.com/repository/docker/spidocker4/vstsagent/tags/ubuntu-jammy-20250619/sha256-949c8b66f7eecba44ec0f64a18493fdb56ebefd4c4d1b107258232d32804aae5)


    > k8s Configuration for both image is the same
---

## 📁 File Structure

```
/
├── Dockerfile
├── script.sh           # Main entrypoint for agent setup and execution
└── README.md           # You're here!
```

---

## ⚙️ Build the Image

```bash
docker build -t custom-ado-agent:latest .
```

---

## 🚀 Run the Container

```bash
docker run -d   --name ado-agent  \ 
-e AZURE_DEVOPS_ORG_URL="https://dev.azure.com/<your-org>" \  
-e AZURE_DEVOPS_PROJECT_NAME="<your-project>" \
-e AZURE_DEVOPS_POOL_NAME="SelfHosted" \
-e AZURE_DEVOPS_POOL_AGENT_NAME="ado-agent" 
-e http_proxy="http://proxy-host:port"  \
-e https_proxy="http://proxy-host:port"  \
-e http_proxy_user="your-username" \
-e http_proxy_pass="your-password" \
-v /path/to/token:/etc/AZURE_DEVOPS_PAT_TOKEN:ro  \
custom-ado-agent:latest
```

> 💡 Make sure the file `/path/to/token` contains your Azure DevOps PAT (Personal Access Token) with **agent management** permissions.

---

## 🌐 Environment Variables

| Variable Name                | Required | Description                                      |
|-----------------------------|----------|--------------------------------------------------|
| `AZURE_DEVOPS_ORG_URL`      | ✅       | Azure DevOps organization URL                    |
| `AZURE_DEVOPS_PROJECT_NAME` | ✅       | Azure DevOps project name                        |
| `AZURE_DEVOPS_POOL_NAME`    | ✅       | Agent pool name                                  |
| `AZURE_DEVOPS_POOL_AGENT_NAME` | ✅    | Logical name of the agent                        |
| `http_proxy`, `https_proxy` | ❌       | Proxy settings (optional)                        |
| `http_proxy_user`           | ❌       | Username for proxy (if authentication required)  |
| `http_proxy_pass`           | ❌       | Password for proxy (required if `http_proxy_user` is set) |

---

## 📄 Logs

Logs are written to:

```
/home/vstsagent/vsts-agent.log
```

You can access them using:

```bash
docker exec -it ado-agent tail -f /home/vstsagent/vsts-agent.log
```

---

## 🔄 Graceful Shutdown

On container termination (`SIGTERM`, `SIGINT`, `EXIT`), the agent automatically:

- Deregisters itself from Azure DevOps
- Cleans up configuration
- Retries `config.sh remove` if needed

---

## 🛠 Debugging Tips

- To enter the container interactively:

```bash
docker exec -it ado-agent /bin/bash
```

- Check the agent configuration status:

```bash
cat /home/vstsagent/vsts-agent.log
```

---

## 📦 What’s Included

- Azure CLI (via `https://aka.ms/InstallAzureCLIDeb`)
- Git
- JQ & curl
- VSTS agent binaries (`vsts-agent-linux-x64-4.258.1.tar.gz`)

---

## 🧼 Cleanup

To stop and remove the agent:

```bash
docker stop ado-agent && docker rm ado-agent
```

To remove the image:

```bash
docker rmi custom-ado-agent:latest
```


## This repo also provides k8s configuration file to deploy the workload. This configuration scale the workloads with the depending upon the event in the queue of a specific Agent Pool.

KEDA (Kubernetes Event Driven Architecture) - This architecture is only benefical when their is microsoft liscence of parallel pipeline execution. ( One pipeline will always be running in the cloud )

Every required configuration is done for you.

Before applying the changes to the configuration file you have to install KEDA operator. [KEDA deployment guide](https://keda.sh/docs/2.17/deploy/)

You just have to play with two configuration file :-
1. adoAgentConfig.yml
2. adoAgentSecrets.yml

1.adoAgentConfig.yml
```yaml
apiVersion: v1
data:
  AZURE_DEVOPS_POOL_AGENT_NAME: <vsts - agent name>      # specify the agent name it will generate a unique name
  AZURE_DEVOPS_POOL_NAME: <specify pool name>
  # http_proxy:                # set proxy if required
  # https_proxy:               # set proxy if required
kind: ConfigMap
metadata:
  namespace: vsts-agent
  name: ado-agent-config

```
2. adoAgentSecrets.yml ( put  base64 encoded format )
``` yaml
apiVersion: v1
data:
  AZURE_DEVOPS_ORG_URL: 
  AZURE_DEVOPS_PAT_TOKEN: 
  AZURE_DEVOPS_PROJECT_NAME: 
kind: Secret
metadata:
  namespace: vsts-agent
  name: vsts-auth-secrets

```

After updating the values in the above file:-
`kubectl apply -f k8s/`
