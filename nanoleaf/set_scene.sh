#! /bin/bash

NANOLEAF_IP=$1
NANOLEAF_TOKEN=$2
SCENE_NAME=$3

curl --location --request PUT "http://${NANOLEAF_IP}:16021/api/v1/${NANOLEAF_TOKEN}/effects" \
  --data "{\"select\" : \"${SCENE_NAME}\"}"
