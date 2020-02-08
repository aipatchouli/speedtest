#!/usr/bin/env bash

cancel() {
	echo ""
	next;
	echo " Abort ..."
	echo " Cleanup ..."
	cleanup;
	echo " Done"
	exit
}

benchinit() {

	# check python
	if  [ ! -e '/usr/bin/python' ]; then
	        echo " Installing Python2 ..."
	            if [ "${release}" == "centos" ]; then
	                    yum -y install python2 > /dev/null 2>&1
			    alternatives --set python /usr/bin/python2 > /dev/null 2>&1
	                else
	                    apt-get -y install python > /dev/null 2>&1
	                fi
	        echo -ne "\e[1A"; echo -ne "\e[0K\r" 
	fi

	# install speedtest-cli
	if  [ ! -e 'speedtest.py' ]; then
		echo " Installing Speedtest-cli ..."
		wget --no-check-certificate https://raw.github.com/sivel/speedtest-cli/master/speedtest.py > /dev/null 2>&1
		echo -ne "\e[1A"; echo -ne "\e[0K\r"
	fi
	chmod a+rx speedtest.py


	# install tools.py
	if  [ ! -e 'tools.py' ]; then
		echo " Installing tools.py ..."
		wget --no-check-certificate https://raw.githubusercontent.com/laset-com/speedtest/master/tools.py > /dev/null 2>&1
		echo -ne "\e[1A"; echo -ne "\e[0K\r"
	fi
	chmod a+rx tools.py

	sleep 0.1

	# start
	start=$(date +%s) 
}

geekbench4() {
	echo "" | tee -a $log
	echo -e " Performing Geekbench v5 CPU Benchmark test. Please wait..."

	GEEKBENCH_PATH=$HOME/geekbench
	mkdir -p $GEEKBENCH_PATH
	curl -s http://cdn.geekbench.com/Geekbench-5.1.0-Linux.tar.gz  | tar xz --strip-components=1 -C $GEEKBENCH_PATH
	GEEKBENCH_TEST=$($GEEKBENCH_PATH/geekbench4 | grep "https://browser")
	GEEKBENCH_URL=$(echo -e $GEEKBENCH_TEST | head -1)
	GEEKBENCH_URL_CLAIM=$(echo $GEEKBENCH_URL | awk '{ print $2 }')
	GEEKBENCH_URL=$(echo $GEEKBENCH_URL | awk '{ print $1 }')
	sleep 0.1
	GEEKBENCH_SCORES=$(curl -s $GEEKBENCH_URL | grep "class='score' rowspan")
	GEEKBENCH_SCORES_SINGLE=$(echo $GEEKBENCH_SCORES | awk -v FS="(>|<)" '{ print $3 }')
	GEEKBENCH_SCORES_MULTI=$(echo $GEEKBENCH_SCORES | awk -v FS="(<|>)" '{ print $7 }')
	
	echo -ne "\e[1A"; echo -ne "\033[0K\r"
	echostyle "## Geekbench v4 CPU Benchmark:"
	echo "" | tee -a $log
	echo -e "  Single Core : $GEEKBENCH_SCORES_SINGLE  $grank" | tee -a $log
	echo -e "   Multi Core : $GEEKBENCH_SCORES_MULTI" | tee -a $log
	[ ! -z "$GEEKBENCH_URL_CLAIM" ] && echo -e "$GEEKBENCH_URL_CLAIM" > geekbench4_claim.url 2> /dev/null
	echo "" | tee -a $log
	echo -e " Cooling down..."
	sleep 0.1
	echo -ne "\e[1A"; echo -ne "\033[0K\r"
	echo -e " Ready to continue..."
	sleep 0.1
	echo -ne "\e[1A"; echo -ne "\033[0K\r"
}


print_end_time() {
	echo "" | tee -a $log
	end=$(date +%s) 
	time=$(( $end - $start ))
	if [[ $time -gt 60 ]]; then
		min=$(expr $time / 60)
		sec=$(expr $time % 60)
		echo -ne " Finished in : ${min} min ${sec} sec"
	else
		echo -ne " Finished in : ${time} sec"
	fi
	#echo -ne "\n Current time : "
	#echo $(date +%Y-%m-%d" "%H:%M:%S)
	printf '\n'
	utc_time=$(date -u '+%F %T')
	echo " Timestamp   : $utc_time GMT" | tee -a $log
	#echo " Finished!"
	echo " Saved in    : $log"
	echo "" | tee -a $log
}

cleanup() {
	rm -f test_file_*;
	rm -f speedtest.py;
	rm -f speedtest.sh;
	rm -f tools.py;
	rm -f ip_json.json;
	rm -f geekbench4_claim.url;
	rm -rf geekbench;
}




case $1 in
   	'gb'|'-gb'|'--gb'|'geek'|'-geek'|'--geek' )
		geekbench4;cleanup;;
esac
