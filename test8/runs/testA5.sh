#!/bin/bash

# starts: 0s
# ends  : 20s
# uses  : 11 GB

GB=$((1024 * 1024 * 1024))
memory=$(( 11 * $GB ))

test8/test8 $memory 20
