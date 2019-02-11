#!/usr/bin/env bash

set -e

health_check() {
    # Check if health check endpoint is alive
    if curl --output /dev/null --silent --fail -k "$1"
    then
        status_code=$(curl --write-out %{http_code} --silent --output /dev/null -k ${1})

        # Check if requests to the health check endpoint produces  200 response
        if [[ "$status_code" -ne 200 ]] ; then
            echo "WSO2 APIM $2 produces an invalid response: $status_code" >>/dev/stderr
            exit 1
        else
            echo "WSO2 APIM $2 is Running!"
        fi
    else
        echo "WSO2 APIM $2 is not alive" >>/dev/stderr
        exit 1
    fi
}

carbonHealthCheckEP="https://localhost:9443/carbon/admin/login.jsp"

health_check ${carbonHealthCheckEP} Carbon
exit 0
