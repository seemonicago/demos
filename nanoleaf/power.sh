#! /bin/bash

NANOLEAF_IP=$1
NANOLEAF_TOKEN=$2
POWER_COMMAND=$3

##To get current state
#curl --location --request GET "http://${NANOLEAF_IP}:16021/api/v1/${NANOLEAF_TOKEN}/state/on"

#POWER_COMMAND = {true|false}

curl --location --request PUT "http://${NANOLEAF_IP}:16021/api/v1/${NANOLEAF_TOKEN}/state" \
  --header "Content-Type: application/json" \
  --data "{
  \"on\": {
    \"value\": ${POWER_COMMAND}
  }
}"
