#!/bin/bash
lineIdx=0
while IFS='' read -r line || [[ -n "$line" ]]
do
	line=$(echo $line)
	if [ "$line" != "" ]
	then
		echo $line
	fi
done < "$1"

