#!/bin/bash
for single in `ls *.c`; do
	gcc -I. -c $single
done

