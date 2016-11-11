#!/bin/bash
# exception tools 
# this shell make the NIC flash broken      
# you can define the time of duration
# nic:eth0     
# time:second
# history:
# 2016/11/09
# author zczhu@fiberhome.com
path=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export path
echo -e "you should input the NIC and the time of duration! \n"
echo -e "after time out, it will recover! \n"
read -p "nic: " nic
echo -e $nic
read -p "time: " time
echo -e $time
for ((i=1; i<=$time; i=i+2))
do
	ifdown $nic
	sleep 1
	ifup $nic
        sleep 1
done
