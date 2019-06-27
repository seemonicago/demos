#! /bin/bash

NANOLEAF_IP=$1
NANOLEAF_TOKEN=$2
curl --location --request GET "http://${NANOLEAF_IP}:16021/api/v1/${NANOLEAF_TOKEN}/" | jq
