#!/bin/bash

mkdir runs
mkdir outputs

for i in {1..3}; do
	echo "echo 'Base job #$i'; echo RES:done" > "runs/file$i.sh"
	mkdir runs/subdir$i
	mkdir outputs/subdir$i
	for j in {1..3}; do
		echo "echo 'Group #$i, job #$j'; echo RES:done" > "runs/subdir$i/job$i-$j.sh"
	done
done

mkdir runs/subdir2/thirdlevel
mkdir outputs/subdir2/thirdlevel
for i in {1..3}; do
	echo "echo 'Third level job #$i'; echo RES:done" > "runs/subdir2/thirdlevel/third$i.sh"
done

mkdir -p runs/subdir4/thirdlevel2
mkdir -p outputs/subdir4/thirdlevel2
for i in {1..3}; do
	echo "echo 'Third level job 2-#$i'; echo RES:done" > "runs/subdir4/thirdlevel2/third2-$i.sh"
done


mkdir runs/subdir3/emptydir
