#!/bin/bash
# concurrent operation of create
#
#
# the operations execute within a general tenant or advanced tenant
#  
# 
# history:
# 2016/11/12
# author zczhu@fiberhome.com
path=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export path
echo -e "Now the shell is beginning! \n"

# set 1 :enable create
# set 0 :for disable create

net_subnet_port_create=$1
router_create=$2
firewall_create=$3
floatingip_create=$4

#setup include
realpath=$(readlink -f "$0")
basedir=$(dirname "$realpath")
export PATH=$PATH:$basedir
. neutron.sh

# create openrc for a tenant
# if you use admin project ,you need change parameter in neutron-openrc-create
neutron-openrc-create

tenantId=`openstack project list | grep $OS_PROJECT_NAME | awk -F"|" '{print $2}'`

# change quota vlue
neutron-quota-update

# the concurrent number of network creation
concurrent_number=1
# cycle number of concurrent operation
cycle_number=1

# configuration for network
# start_ip for network
IPStart=10
# external network
ext_net="ext-net"

for ((j=1; j<=$cycle_number; j=j+1))
do
    for((i=1; i<=$concurrent_number; i=i+1))
    do
        IPStart=$[IPStart+1]
        {
        # create network
        if [ $net_subnet_port_create = "1" ] ; then
            neutron_network_subnet_port_create 
        fi

        # create router
        if [ $router_create = "1" ]; then
            neutron_router_create
        fi

        #create fw
	if [ $firewall_create = "1" ]; then
            neutron_fw_create
        fi

        #create floatingip
        if [ $floatingip_create = "1" ]; then
            neutron_floatingip_create
        fi
        } &
    done
    sleep 5
    wait
    sleep 15
done
neutron quota-update --network $networkQuota --subnet $subnetQuota --port $portQuota --router $routerQuota --tenant-id $tenantId >/dev/null
echo -e "well done! \n"
