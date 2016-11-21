#!/bin/env bash

net_name='testDhcp'
net_id=''
subnet_name='testDhcp-subnet'
subnet_id=''
CIDR='192.168.20.0/24'
vm_name='vm-to-test-dhcp'
count=6
FILE='env_for_cleanup' # a file to save vars for clean up process

source $FILE
#openrc_file is a var in $FILE
source $openrc_file

net_id=`neutron net-create $net_name |grep -w id |awk '{print $4}'`
subnet_id=`neutron subnet-create --name $subnet_name --enable-dhcp $net_id $CIDR |grep -w id \
|awk '{print $4}'`

#save these var into a file in order to clean up afterwards
echo "net_id=$net_id" >> $FILE
echo "subnet_id=$subnet_id" >> $FILE
echo "vm_name=$vm_name" >> $FILE
echo "count=6" >> $FILE

count=6
while [ $count -gt 1 ]
do
	nova boot --flavor m1.tiny --image cirros \
	--nic net-id=$net_id ${vm_name}-${count} & 
	count=$[ $count - 1 ]
done



