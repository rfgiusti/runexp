#!/bin/bash

# starts: 0s
# ends  : 18s
# uses  : 4 GB

GB=$((1024 * 1024 * 1024))
memory=$(( 4 * $GB ))

test8/test8 $memory 18
