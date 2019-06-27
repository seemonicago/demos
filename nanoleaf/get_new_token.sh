#! /bin/bash

NANOLEAF_IP=$1
curl --location --request POST "http://${NANOLEAF_IP}:16021/api/v1/new"
