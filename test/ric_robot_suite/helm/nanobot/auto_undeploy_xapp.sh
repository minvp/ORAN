#!/bin/bash
sleep 2
curl -v -X POST "http://10.100.136.133:8080/ric/v1/deregister" -H "accept: application/json" -H "Content-Type: application/json" -d '{"appName": "bouncer-xapp", "appInstanceName": "bouncer-xapp"}'
sleep 3
curl -X DELETE http://0.0.0.0:8090/api/charts/bouncer-xapp/2.0.0
sleep 3
dms_cli uninstall bouncer-xapp ricxapp
sleep 3
