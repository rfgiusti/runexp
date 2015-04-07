#!/bin/bash

rm -f runs/*
rm -f outputs/*

for i in {1..30}; do
	sleeptime=$(( $RANDOM % 8 + 10 ))
	echo "sleep $sleeptime" > "runs/run$i.sh"
done
