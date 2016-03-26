#!/bin/bash

# starts: 20s
# ends  : 36s
# uses  : 8 GB

GB=$((1024 * 1024 * 1024))
memory=$(( 8 * $GB ))

test8/test8 $memory 16
