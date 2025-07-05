#!/bin/bash

set -e

LOG_FILE="/home/vstsagent/vsts-agent.log"
RETRY_COUNT=3
SLEEP_BETWEEN_RETRIES=10

export AGENT_HOME="/opt/vstsagent"

if [ -n "${http_proxy}" ] && [ -n "${https_proxy}" ]; then

	echo "configuring agent behind proxy server..."

	http_url=$(echo "${http_proxy}" | sed 's|http://||')
	https_url=$(echo "${https_proxy}" | sed 's|http://||')

	if [ -n "${http_proxy_user}" ]; then

		if [ -z "${http_proxy_pass}" ]; then

			echo 1>&2 "Setting http_proxy_pass is missing for user ${http_proxy_pass}..."
			exit 1

		fi

		export http_proxy="http://${http_proxy_user}:${http_proxy_pass}@${http_url}"
		export https_proxy="http://${http_proxy_user}:${http_proxy_pass}@${https_url}"

	fi

fi


if [ -z "${AZURE_DEVOPS_ORG_URL}" ] || \
   [ -z "${AZURE_DEVOPS_PROJECT_NAME}" ] || \
   [ -z "${AZURE_DEVOPS_POOL_AGENT_NAME}" ] || \
   [ -z "${AZURE_DEVOPS_POOL_NAME}" ]; then

    echo 1>&2 "Missing one of the required environment variables: AZURE_DEVOPS_ORG_URL, AZURE_DEVOPS_PROJECT_NAME, AZURE_DEVOPS_POOL_AGENT_NAME, AZURE_DEVOPS_POOL_NAME"
    exit 1

fi

print_header() {

  lightcyan="\033[1;36m"
  nocolor="\033[0m"
  echo -e "\n${lightcyan}$1${nocolor}\n"

}

cleanup() {
    trap "" EXIT
    exec $AGENT_HOME/shutdown.sh
}

trap "cleanup; exit 0" EXIT
trap "cleanup; exit 130" INT
trap "cleanup; exit 143" TERM

echo "$(date) - Starting VSTS agent configuration..." | tee -a "$LOG_FILE"


if [ -e $AGENT_HOME/config.sh ]; then
    # Retry logic for config.sh
    for attempt in $(seq 1 $RETRY_COUNT); do

            print_header "$(date) - Attempt $attempt to configure the agent..." | tee -a "$LOG_FILE"
            $AGENT_HOME/config.sh --unattended \
                --url "${AZURE_DEVOPS_ORG_URL}" \
                --auth pat \
    	        --token "$(cat /etc/AZURE_DEVOPS_PAT_TOKEN)" \
                --projectName "${AZURE_DEVOPS_PROJECT_NAME}" \
    	        --agent "${AZURE_DEVOPS_POOL_AGENT_NAME}-$(hostname)" \
                --pool "${AZURE_DEVOPS_POOL_NAME}" \
                --acceptTeeEula \
                --replace & wait $! && break

            echo "$(date) - Configuration failed. Retrying in ${SLEEP_BETWEEN_RETRIES}s..." | tee -a "$LOG_FILE"
            sleep $SLEEP_BETWEEN_RETRIES

            if [ "$attempt" -eq "$RETRY_COUNT" ]; then
                echo "$(date) - Configuration failed after $RETRY_COUNT attempts." | tee -a "$LOG_FILE"
                exit 1
            fi

    done
else
    print_header "$(date) - Config file not found check the configuration and debug it." | tee -a "$LOG_FILE"
    exit 1
fi

print_header "$(date) - Running the VSTS agent..." | tee -a "$LOG_FILE"

$AGENT_HOME/run-docker.sh