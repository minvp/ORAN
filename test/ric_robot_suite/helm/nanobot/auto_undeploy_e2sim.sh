#!/bin/bash

sleep 3
cd ~/test/ric_benchmarking/e2-interface/e2sim/e2sm_examples/kpm_e2sm/helm
sleep 1
helm uninstall e2sim -n test
