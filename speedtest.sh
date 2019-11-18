#!/usr/bin/env bash

about() {
	echo ""
	echo " ========================================================= "
	echo " \               Speedtest Bench.Monster                 / "
	echo " \         https://bench.monster/speedtest.html          / "
	echo " \    System info, Geekbench, I/O test and speedtest     / "
	echo " \                  v1.4.6   2019-10-29                  / "
	echo " ========================================================= "
	echo ""
}

cancel() {
	echo ""
	next;
	echo " Abort ..."
	echo " Cleanup ..."
	cleanup;
	echo " Done"
	exit
}

trap cancel SIGINT

benchram="$HOME/tmpbenchram"
NULL="/dev/null"

echostyle(){
	if hash tput 2>$NULL; then
		echo " $(tput setaf 6)$1$(tput sgr0)"
		echo " $1" >> $log
	else
		echo " $1" | tee -a $log
	fi
}

benchinit() {
	# check release
	if [ -f /etc/redhat-release ]; then
	    release="centos"
	elif cat /etc/issue | grep -Eqi "debian"; then
	    release="debian"
	elif cat /etc/issue | grep -Eqi "ubuntu"; then
	    release="ubuntu"
	elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
	    release="centos"
	elif cat /proc/version | grep -Eqi "debian"; then
	    release="debian"
	elif cat /proc/version | grep -Eqi "ubuntu"; then
	    release="ubuntu"
	elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
	    release="centos"
	fi

	# check OS
	#if [ "${release}" == "centos" ]; then
	#                echo "Checking OS ... [ok]"
	#else
	#                echo "Error: This script must be run on CentOS!"
	#		exit 1
	#fi
	#echo -ne "\e[1A"; echo -ne "\e[0K\r"
	
	# check root
	[[ $EUID -ne 0 ]] && echo -e "Error: This script must be run as root!" && exit 1
	

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

	# check curl
	if  [ ! -e '/usr/bin/curl' ]; then
	        echo " Installing Curl ..."
	            if [ "${release}" == "centos" ]; then
	                yum -y install curl > /dev/null 2>&1
	            else
	                apt-get -y install curl > /dev/null 2>&1
	            fi
		echo -ne "\e[1A"; echo -ne "\e[0K\r"
	fi

	# check wget
	if  [ ! -e '/usr/bin/wget' ]; then
	        echo " Installing Wget ..."
	            if [ "${release}" == "centos" ]; then
	                yum -y install wget > /dev/null 2>&1
	            else
	                apt-get -y install wget > /dev/null 2>&1
	            fi
		echo -ne "\e[1A"; echo -ne "\e[0K\r"
	fi
	
	# check bzip2
	if  [ ! -e '/usr/bin/bzip2' ]; then
	        echo " Installing bzip2 ..."
	            if [ "${release}" == "centos" ]; then
	                yum -y install bzip2 > /dev/null 2>&1
	            else
	                apt-get -y install bzip2 > /dev/null 2>&1
	            fi
		echo -ne "\e[1A"; echo -ne "\e[0K\r"
	fi
	
	# check tar
	if  [ ! -e '/usr/bin/tar' ]; then
	        echo " Installing tar ..."
	            if [ "${release}" == "centos" ]; then
	                yum -y install tar > /dev/null 2>&1
	            else
	                apt-get -y install tar > /dev/null 2>&1
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

	sleep 5

	# start
	start=$(date +%s) 
}

get_opsy() {
    [ -f /etc/redhat-release ] && awk '{print ($1,$3~/^[0-9]/?$3:$4)}' /etc/redhat-release && return
    [ -f /etc/os-release ] && awk -F'[= "]' '/PRETTY_NAME/{print $3,$4,$5}' /etc/os-release && return
    [ -f /etc/lsb-release ] && awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release && return
}

next() {
    printf "%-75s\n" "-" | sed 's/\s/-/g' | tee -a $log
}
next2() {
    printf "%-57s\n" "-" | sed 's/\s/-/g'
}

delete() {
    echo -ne "\e[1A"; echo -ne "\e[0K\r"
}

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
	sleep 10
	GEEKBENCH_SCORES=$(curl -s $GEEKBENCH_URL | grep "class='score' rowspan")
	GEEKBENCH_SCORES_SINGLE=$(echo $GEEKBENCH_SCORES | awk -v FS="(>|<)" '{ print $3 }')
	GEEKBENCH_SCORES_MULTI=$(echo $GEEKBENCH_SCORES | awk -v FS="(<|>)" '{ print $7 }')
	
	if [[ $GEEKBENCH_SCORES_SINGLE -le 1700 ]]; then
		grank="(POOR)"
	elif [[ $GEEKBENCH_SCORES_SINGLE -ge 1700 && $GEEKBENCH_SCORES_SINGLE -le 2300 ]]; then
		grank="(FAIR)"
	elif [[ $GEEKBENCH_SCORES_SINGLE -ge 2300 && $GEEKBENCH_SCORES_SINGLE -le 3000 ]]; then
		grank="(GOOD)"
	elif [[ $GEEKBENCH_SCORES_SINGLE -ge 3000 && $GEEKBENCH_SCORES_SINGLE -le 4000 ]]; then
		grank="(VERY GOOD)"
	else
		grank="(EXCELLENT)"
	fi
	
	echo -ne "\e[1A"; echo -ne "\033[0K\r"
	echostyle "## Geekbench v4 CPU Benchmark:"
	echo "" | tee -a $log
	echo -e "  Single Core : $GEEKBENCH_SCORES_SINGLE  $grank" | tee -a $log
	echo -e "   Multi Core : $GEEKBENCH_SCORES_MULTI" | tee -a $log
	[ ! -z "$GEEKBENCH_URL_CLAIM" ] && echo -e "$GEEKBENCH_URL_CLAIM" > geekbench4_claim.url 2> /dev/null
	echo "" | tee -a $log
	echo -e " Cooling down..."
	sleep 9
	echo -ne "\e[1A"; echo -ne "\033[0K\r"
	echo -e " Ready to continue..."
	sleep 3
	echo -ne "\e[1A"; echo -ne "\033[0K\r"
}


log="$HOME/speedtest.log"
true > $log

case $1 in
	'info'|'-i'|'--i'|'-info'|'--info' )
		about;sleep 3;next;get_system_info;print_system_info;;
	'version'|'-v'|'--v'|'-version'|'--version')
		next;about;next;;
   	'gb'|'-gb'|'--gb'|'geek'|'-geek'|'--geek' )
		next;geekbench4;next;cleanup;;
	'io'|'-io'|'--io'|'ioping'|'-ioping'|'--ioping' )
		next;iotest;write_io;next;;
	'dd'|'-dd'|'--dd'|'disk'|'-disk'|'--disk' )
		about;ioping;next2;;
	'speed'|'-speed'|'--speed'|'-speedtest'|'--speedtest'|'-speedcheck'|'--speedcheck' )
		about;benchinit;next;print_speedtest;next;cleanup;;
	'ip'|'-ip'|'--ip'|'geoip'|'-geoip'|'--geoip' )
		about;benchinit;next;ip_info4;next;cleanup;;
	'bench'|'-a'|'--a'|'-all'|'--all'|'-bench'|'--bench'|'-Global' )
		bench_all;;
	'about'|'-about'|'--about' )
		about;;
	'usa'|'-usa'|'--usa'|'us'|'-us'|'--us'|'USA'|'-USA'|'--USA' )
		usa_bench;;
	'europe'|'-europe'|'--europe'|'eu'|'-eu'|'--eu'|'Europe'|'-Europe'|'--Europe' )
		europe_bench;;
	'asia'|'-asia'|'--asia'|'as'|'-as'|'--as'|'Asia'|'-Asia'|'--Asia' )
		asia_bench;;
	'sa'|'-sa'|'--sa'|'-South-America' )
		sa_bench;;
	'ukraine'|'-ukraine'|'--ukraine'|'ua'|'-ua'|'--ua'|'ukr'|'-ukr'|'--ukr'|'Ukraine'|'-Ukraine'|'--Ukraine' )
		ukraine_bench;;
	'lviv'|'-lviv'|'--lviv'|'-Lviv'|'--Lviv' )
		lviv_bench;;
	'M-East'|'-M-East'|'--M-East'|'-m-east'|'--m-east'|'-meast'|'--meast'|'-Middle-East'|'-me' )
		meast_bench;;
	'ru'|'-ru'|'--ru'|'rus'|'-rus'|'--rus'|'russia'|'-russia'|'--russia'|'Russia'|'-Russia'|'--Russia' )
		ru_bench;;
	'-s'|'--s'|'share'|'-share'|'--share' )
		bench_all;
		is_share="share"
		if [[ $2 == "" ]]; then
			sharetest ubuntu;
		else
			sharetest $2;
		fi
		;;
	'debug'|'-d'|'--d'|'-debug'|'--debug' )
		get_ip_whois_org_name;;
*)
    bench_all;;
esac



if [[  ! $is_share == "share" ]]; then
	case $2 in
		'share'|'-s'|'--s'|'-share'|'--share' )
			if [[ $3 == '' ]]; then
				sharetest ubuntu;
			else
				sharetest $3;
			fi
			;;
	esac
fi
