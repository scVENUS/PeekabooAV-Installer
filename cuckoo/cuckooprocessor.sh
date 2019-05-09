#!/usr/bin/env bash

# cuckoo processor wrapper to run not only cuckoo but also several processor instances
# while conserving stdout for parsing in the peekaboo cuckoo wrapper

# by Felix Bauer
#  felix.bauer@atos.net

set -x
pids=()

cuckoo="/opt/cuckoo/bin/cuckoo"
n=5

# trigger a connection to the database to force schema creation if that hasn't
# happened yet. This can be the case after a call to cuckoo clean. If we don't
# do this, below starts of process instances and the main cuckoo process will
# race each other and run into conflicts (i.e. table already exists and the
# like). Does *not* submit any jobs, obviously.
$cuckoo submit

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
