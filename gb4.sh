#!/usr/bin/env bash

geekbench4() {
	echo "" | tee -a $log
	echo -e " Performing Geekbench v4 CPU Benchmark test. Please wait..."

	GEEKBENCH_PATH=$HOME/geekbench
	mkdir -p $GEEKBENCH_PATH
	curl -s http://cdn.geekbench.com/Geekbench-4.4.2-Linux.tar.gz  | tar xz --strip-components=1 -C $GEEKBENCH_PATH
	GEEKBENCH_TEST=$($GEEKBENCH_PATH/geekbench4 | grep "https://browser")
	GEEKBENCH_URL=$(echo -e $GEEKBENCH_TEST | head -1)
	GEEKBENCH_URL_CLAIM=$(echo $GEEKBENCH_URL | awk '{ print $2 }')
	GEEKBENCH_URL=$(echo $GEEKBENCH_URL | awk '{ print $1 }')
	sleep 1
	GEEKBENCH_SCORES=$(curl -s $GEEKBENCH_URL | grep "class='score' rowspan")
	GEEKBENCH_SCORES_SINGLE=$(echo $GEEKBENCH_SCORES | awk -v FS="(>|<)" '{ print $3 }')
	GEEKBENCH_SCORES_MULTI=$(echo $GEEKBENCH_SCORES | awk -v FS="(<|>)" '{ print $7 }')
	
	
	echo -ne "\e[1A"; echo -ne "\033[0K\r"
	
	echo "" | tee -a $log
	echo -e "  Single Core : $GEEKBENCH_SCORES_SINGLE  $grank" | tee -a $log
	echo -e "   Multi Core : $GEEKBENCH_SCORES_MULTI" | tee -a $log
	[ ! -z "$GEEKBENCH_URL_CLAIM" ] && echo -e "$GEEKBENCH_URL_CLAIM" > geekbench4_claim.url 2> /dev/null
	echo "" | tee -a $log
	
}


