#!/bin/bash

rm -f runs/*
rm -f outputs/*

for i in {1..30}; do
	sleeptime=$(( $RANDOM % 4 + 2 ))
	echo "sleep $sleeptime" > "runs/run$i.sh"
	echo "echo RES:done" >> "runs/run$i.sh"
done
