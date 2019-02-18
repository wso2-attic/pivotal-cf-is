#!/usr/bin/env bash

set -e

isAlive=0

health_check() {
    # Check if health check endpoint is alive
    if curl --output /dev/null --silent --fail -k "$1"
    then
        status_code=$(curl --write-out %{http_code} --silent --output /dev/null -k ${1})

        # Check if requests to the health check endpoint produces  200 response
        if [[ "$status_code" -ne 200 ]] ; then
            >&2 echo "WSO2 IS $2 produces an invalid response: $status_code"
            exit 1
        else
            echo "WSO2 IS $2 is Running!"
            isAlive=1
        fi
    else
        >&2 echo "WSO2 IS $2 is not alive. Retrying in 10s..."
        isAlive=0
    fi
}

carbonHealthCheckEP="https://localhost:9443/carbon/admin/login.jsp"
COUNTER=0

# While the endpoint is not alive, and the server has been retrying for less than 3 minutes
while [ ${isAlive} -eq 0 ]&&[ ${COUNTER} -lt 18 ]; do
    sleep 10s
    health_check ${carbonHealthCheckEP} Carbon
    let COUNTER=COUNTER+1
done

if [ ${isAlive} -eq 0 ]; then
    >&2 echo "Could not connect to WSO2 IS $2. Exiting..."
    exit 1
fi

exit 0
