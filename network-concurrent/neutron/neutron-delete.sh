#!/bin/bash -x
#  delete operation of neutron
#
# the operations execute within a general tenant or advanced tenant   
# 
# history:
# 2016/11/14
# author zczhu@fiberhome.com
path=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export path
echo -e "Now the shell is beginning! \n"

#setup include
realpath=$(readlink -f "$0")
basedir=$(dirname "$realpath")
export PATH=$PATH:$basedir
. neutron.sh

# create openrc for a tenant
# if you use admin project ,you need change parameter in neutron-openrc-create
neutron-openrc-create

tenantId=`openstack project list | grep $OS_PROJECT_NAME | awk -F"|" '{print $2}'`

#begin delete ipsec_vpn
neutron_ipsec_vpn_delete

#begin delete floatingip
neutron_floatingip_delete

# begin delete fw
neutron_fw_delete

# begin delete router
neutron_router_delete

# begin delete network subnet and port
neutron_network_subnet_port_delete

echo -e "well done! delete all the neutron resource!\n"
