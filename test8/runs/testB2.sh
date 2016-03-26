#!/bin/bash

# starts: 20
# ends  : 42
# uses  : 4 GB

GB=$((1024 * 1024 * 1024))
memory=$(( 4 * $GB ))

test8/test8 $memory 22
