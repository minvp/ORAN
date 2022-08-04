#!/bin/bash

sleep 2
cd ~/test/ric_benchmarking/e2-interface/e2sim/e2sm_examples/kpm_e2sm/helm
sleep 2
helm install e2sim --namespace test .


