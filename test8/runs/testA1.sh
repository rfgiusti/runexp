#!/bin/bash

# starts: 0s
# ends  : 16s
# uses  : --

GB=$((1024 * 1024 * 1024))
memory=512

test8/test8 $memory 16
