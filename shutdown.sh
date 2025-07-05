#!/bin/bash

RETRY_COUNT=5
AGENT_HOME="/opt/vstsagent"

if [ -e $AGENT_HOME/config.sh ]; then

    for attempt in $(seq 1 $RETRY_COUNT); do

        $AGENT_HOME/config.sh remove --unattended --auth pat \
    			    --token $(cat /etc/AZURE_DEVOPS_PAT_TOKEN) && break

        if [ "${attempt}" -eq "${RETRY_COUNT}" ]; then

            echo "$(date) - failed to unregister the agent from ado server"
            exit 1

        fi

    done

else
    echo "$(date) - Config file not found check the configuration and debug it."
    exit 1
fi