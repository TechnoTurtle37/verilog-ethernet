#!/bin/bash

count=0

str=""

# Directory for PCAP files
for file in 2018/03/20/*
do
	count=$(($count + 1))
	echo "Start of PCAP file $count"
	str+=$(./bin/dns_parse -m "" -c -t -n -r -D 0 "$file")
	str+="\n\n"
done

echo -e "$str" > logfile.txt

python3 log_file_parse.py