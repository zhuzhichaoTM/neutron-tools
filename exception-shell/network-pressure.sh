#!/bin/bash
# exception tools 
# this shell make the network performance attenuation by 90%   
# you can define the time of duration      
#       
# ref:https://www.ibm.com/developerworks/cn/linux/l-netperf/
# history:
# 2016/11/24
# author zczhu@fiberhome.com
path=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export path
host_vip=$1
cir_time=$2
pressure=$3
ftp_weight=$4
sql_weight=$5
http_weight=$6

# ftp_weight +sql_weight+http_weight =1
# kill netfperf process
PROCESS=`ps -ef|grep netperf |grep -v grep |awk '{print $2}'`
for i in $PROCESS
do
  kill -9 $i
done

tcp_stream_value=`netperf -t TCP_STREAM -H $host_vip -l 2 -- -m 128 |awk '{print$5}'|grep -iv '^$' |awk 'NR==4{print}'`
tcp_rr=`netperf -t TCP_RR -H $host_vip -l 5 -- -r 32,1024 |awk '{print$6}' |grep -iv '^$'|awk 'NR==5{print}'`
tcp_crr=`netperf -t TCP_CRR -H $host_vip -l 2 -- -r 32,1024 |awk '{print$6}' |grep -iv '^$' |awk 'NR==5{print}'`
echo -e "netperf :TCP_STREAM is $tcp_stream_value! \n"
echo -e "netperf :TCP_RR is $tcp_rr! \n"
echo -e "netperf :TCP_CRR is $tcp_crr! \n"

concurrent_time_ftp=0
concurrent_time_sq=0
concurrent_time_http=0

flag_1="false"
flag_2="false"
flag_3="false"

while [ $flag_1 = "false" ]
do
    PROCESS=`ps -ef|grep netperf |grep -v grep |awk '{print $2}'`
    for i in $PROCESS
    do
        kill -9 $i
    done

    for ((i=1; i<=$concurrent_time_ftp; i=i+1))
    do
        netperf -t TCP_STREAM -H $host_vip -l 5 -- -m 64 >/dev/null &
    done
    tmp_tcp_stream_value=`netperf -t TCP_STREAM -H $host_vip -l 2 -- -m 128 |awk '{print$5}'|grep -iv '^$' |awk 'NR==4{print}'`
    wait
    tmp_press_ftp=`echo "$tcp_stream_value - $tcp_stream_value * $pressure * $ftp_weight" |bc`
    tmp_press_ftp_range=`echo "$tmp_press_ftp * 1.1" |bc`
    if [ $(echo "$tmp_tcp_stream_value > $tmp_press_ftp_range"|bc) -eq 1 ]; then
        concurrent_time_ftp=$[concurrent_time_ftp+1]
    else
        echo -e "current:TCP_STREAM is $tmp_tcp_stream_value!\n"
        flag_1="true"
    fi
    echo -e "current:TCP_STREAM is $tmp_tcp_stream_value!\n"
done

while [ $flag_2 = "false" ]
do
    PROCESS=`ps -ef|grep netperf |grep -v grep |awk '{print $2}'`
    for i in $PROCESS
    do
        kill -9 $i
    done    

    for ((i=1; i<=$concurrent_time_sq; i=i+1))
    do
        netperf -t TCP_RR -H $host_vip -l 5 -- -r 32,8192 >/dev/null &
    done
    tmp_tcp_rr=`netperf -t TCP_RR -H $host_vip -l 3 -- -r 32,1024 |awk '{print$6}' |grep -iv '^$'|awk 'NR==5{print}'`
    wait
    tmp_press_sql=`echo "$tcp_rr - $tcp_rr * $pressure * $sql_weight" |bc`
    tmp_press_sql_range=`echo "$tmp_press_sql * 1.15" |bc`
    if [ $(echo "$tmp_tcp_rr > $tmp_press_sql_range"|bc) -eq 1 ]; then
        concurrent_time_sq=$[concurrent_time_sq+1]
    else
        echo -e "current TCP_RR is $tmp_tcp_rr! \n"
        flag_2="true"
    fi
    echo -e "current TCP_RR is $tmp_tcp_rr! \n"
done

while [ $flag_3 = "false" ]
do
    PROCESS=`ps -ef|grep netperf |grep -v grep |awk '{print $2}'`
    for i in $PROCESS
    do
        kill -9 $i
    done
    
    for ((i=1; i<=$concurrent_time_http; i=i+1))
    do
        netperf -t TCP_RR -H $host_vip -l 5 -- -r 32,40960 >/dev/null &
    done
    tmp_tcp_crr=`netperf -t TCP_CRR -H $host_vip -l 2 -- -r 32,1024 |awk '{print$6}' |grep -iv '^$' |awk 'NR==5{print}'`
    while [ $(echo "$tmp_tcp_crr < 10"|bc) -eq 1 ]
    do
        sleep 2
        tmp_tcp_crr=`netperf -t TCP_CRR -H $host_vip -l 2 -- -r 32,1024 |awk '{print$6}' |grep -iv '^$' |awk 'NR==5{print}'`
    done
    wait
    tmp_press_http=`echo "$tcp_crr - $tcp_crr * $pressure * $http_weight" |bc`
    tmp_press_http_range=`echo "$tmp_press_http * 1.1" |bc`
    if [ $(echo "$tmp_tcp_crr > $tmp_press_http_range"|bc) -eq 1 ]; then
        concurrent_time_http=$[concurrent_time_http+1]
    else
        echo -e "current TCP_CRR is $tmp_tcp_crr! \n"
        flag_3="true"
    fi
    echo -e "current TCP_CRR is $tmp_tcp_crr $tmp_press_http  $tmp_press_http_range $concurrent_time_http! \n"
done

if [ $flag_1 = "true" -a $flag_2 = "true" -a $flag_2 = "true" ]; then
    echo -e "add network presure success ! \n"
    echo -e "current_value:$tmp_tcp_stream_value - $tmp_tcp_rr - $tmp_tcp_crr"
    echo -e "concurrent_time: $concurrent_time_ftp - $concurrent_time_sq - $concurrent_time_http"
else
    echo -e "add network presure fail try again ! \n"
    exit 1
fi

for ((j=1; j<=$cir_time; j=j+1))
do 
    for ((i=1; i<=$concurrent_time_ftp; i=i+1))
    do
        netperf -t TCP_STREAM -H $host_vip -l 5 -- -m 64 >/dev/null &
    done
    for ((i=1; i<=$concurrent_time_sq; i=i+1))
    do
        netperf -t TCP_RR -H $host_vip -l 5 -- -r 32,8192 >/dev/null &
    done
    for ((i=1; i<=$concurrent_time_http; i=i+1))
    do
        netperf -t TCP_RR -H $host_vip -l 5 -- -r 32,40960 >/dev/null &
    done
    echo -e "adding networkpure"
    wait
done
echo -e "well done"
