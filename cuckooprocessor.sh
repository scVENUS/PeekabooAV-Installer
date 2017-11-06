#!/usr/bin/env bash

# cuckoo processor wrapper to run not only cuckoo but also several processor instances
# while conserving stdout for parsing in the peekaboo cuckoo wrapper

# by Felix Bauer
#  felix.bauer@atos.net

set -x
pids=()

cuckoo="/usr/local/bin/cuckoo"
n=5

for p in $(seq 1 $n)
do
  $cuckoo process instance$p &
  pids[$p]=$!
done

$cuckoo

for p in $(seq 1 $n)
do
  kill ${pids[$p]}
done
