#!/bin/bash

# starts: 0s
# ends  : 40s
# uses  : 14 GB

GB=$((1024 * 1024 * 1024))
memory=$(( 14 * $GB ))

test8/test8 $memory 40
