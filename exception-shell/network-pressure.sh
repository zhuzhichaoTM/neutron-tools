#!/bin/bash
# exception tools 
# this shell make the network performance attenuation by 90%   
# you can define the time of duration      
#       
# ref:https://www.ibm.com/developerworks/cn/linux/l-netperf/
# history:
# 2016/11/09
# author zczhu@fiberhome.com
path=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export path
echo -e "you should input the host_vip and the time of duration! \n"
read -p "host_vip: " host_vip
echo -e $host_vip
read -p "time: " time
echo -e $time
for ((j=1; j<=$time; j=j+1))
do
	for ((i=1; i<=6; i=i+1))
	do
		netperf -t TCP_STREAM -H $host_vip -l 60 -- -m 2048 &
	done
	for ((i=1; i<=6; i=i+1))
        do
        	netperf -t TCP_RR -H $host_vip -- -r 32,1024 &
	done
	for ((i=1; i<=6; i=i+1))
        do
        	netperf -t TCP_CRR -H $host_vip -- -r 32,1024 &
	done
	wait
done
echo -e "done"

