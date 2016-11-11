#!/bin/bash
# exception tools 
# this shell make the NIC broken which you choose      
# you can define the time of duration
# after time out, it will recover
# 
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
ifdown $nic
sleep $time
ifup $nic
