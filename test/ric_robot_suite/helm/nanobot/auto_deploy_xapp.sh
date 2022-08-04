#!/bin/bash

cd ~/bouncer/Bouncer
docker run --rm -u 0 -it -d -p 8090:8080 -e DEBUG=1 -e STORAGE=local -e STORAGE_LOCAL_ROOTDIR=/charts -v $(pwd)/charts:/charts chartmuseum/chartmuseum:latest
export CHART_REPO_URL=http://0.0.0.0:8090
sleep 3
dms_cli onboard init/config-file.json init/schema.json
sleep 3
curl -X GET http://0.0.0.0:8090/api/charts | jq .
sleep 3
dms_cli install bouncer-xapp 2.0.0 ricxapp
sleep 3
curl -v -X POST "http://10.100.136.133:8080/ric/v1/register" -H "accept: application/json" -H "Content-Type: application/json" -d "@bouncer-register.json"
sleep 5
