#!/bin/bash

NUM_SUCCESS=60
NUM_FAILURES=60

[[ -d runs ]] || mkdir runs
[[ -d outputs ]] || mkdir outputs

for i in `seq 1 $NUM_SUCCESS`; do
	echo 'echo RES:done' > runs/success$i.sh
done
for i in `seq 1 $NUM_FAILURES`; do
	echo 'echo RES:failed!' > runs/fail$i.sh
done
