#!/bin/bash
# concurrent operation of network and subnet
#
#
# the operations execute within a general tenant or advanced tenant   
# you can define the number of network to  create
# and define the  number of subnet within a network to create
#  
# 
# history:
# 2016/11/12
# author zczhu@fiberhome.com
path=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export path
echo -e "Now the shell is beginning! \n"

# please change them according to your openstack environment
# use admin project
source_file_path="/root"
openrc_name="admin-openrc"

# use private tenant project
# please change them according to your tenant info
tenant_openrc_name="zzc_project-openrc.sh"
OS_PROJECT_NAME="zzc_project"
OS_TENANT_NAME="zzc_project"
OS_USERNAME="zzc"
OS_PASSWORD="123"

# default set false that means you choose your private tenant
# set true that means you choose admin tenant
project_name_admin=false

if $project_name_admin ; then
    source $source_file_path/$openrc_name
    echo -e "Now the shell is beginning in $openrc_name! \n"
else
    if [ -f "$source_file_path/$tenant_openrc_name" ]; then
        echo "the zzc_project-openrc.sh exists"
    else
        echo "copy the admin-openrc"
        cp $source_file_path/$openrc_name $source_file_path/$tenant_openrc_name
        sed -i -e "3cexport OS_PROJECT_NAME=$OS_PROJECT_NAME" $source_file_path/$tenant_openrc_name
        sed -i -e "4cexport OS_TENANT_NAME=$OS_TENANT_NAME" $source_file_path/$tenant_openrc_name
        sed -i -e "5cexport OS_USERNAME=$OS_USERNAME" $source_file_path/$tenant_openrc_name
        sed -i -e "6cexport OS_PASSWORD=$OS_PASSWORD" $source_file_path/$tenant_openrc_name
    fi
    source $source_file_path/$tenant_openrc_name
    echo -e "Now the shell is beginning in $tenant_openrc_name! \n"
fi
# begin create network&&subnet

tenantId=`openstack project list | grep $OS_PROJECT_NAME | awk -F"|" '{print $2}'`
IPStart=10
# the concurrent number of network creation
concurrent_number=3
# cycle number of concurrent operation
cycle_number=3

# old  quota value
networkQuota=`neutron quota-show $tenantId | grep -w network | awk -F"|" '{print $3}'`
subnetQuota=`neutron quota-show $tenantId | grep -w subnet | awk -F"|" '{print $3}'`
portQuota=`neutron quota-show $tenantId | grep -w port | awk -F"|" '{print $3}'`
echo -e "odl Quota:\n"
echo -e "networkQuota:$networkQuota\n"
echo -e "subnetQuota:$subnetQuota\n"
echo -e "portQuota:$portQuota\n"

# update new quota
echo -e "new update quota:\n"
neutron quota-update --network 50 --subnet 100 --port 400 --tenant-id $tenantId

for ((j=1; j<=$cycle_number; j=j+1))
do
    for((i=1; i<=$concurrent_number; i=i+1))
    do
        IPStart=$[IPStart+1]
        {
        # create network
        neutron net-create --admin-state-up "$OS_PROJECT_NAME-net-$j-$i" >/dev/null
        sleep 3
        netId=`neutron net-list | grep "$OS_PROJECT_NAME-net-$j-$i" | awk -F "|"  '{print $2}'`

        if [ -n "$netId" ];then
        echo -e "netId:$netId \n"
        # create subnet
        neutron subnet-create \
--gateway 192.168.$IPStart.1 --allocation-pool start=192.168.$IPStart.10,end=192.168.$IPStart.100 \
--dns-nameserver 10.19.8.10 --enable-dhcp \
--ip-version 4 --name $OS_PROJECT_NAME-subnet-$IPStart $netId 192.168.$IPStart.0/24 >/dev/null
        sleep 5
        subnetId=`neutron subnet-list | grep "$OS_PROJECT_NAME-subnet-$IPStart" | awk -F "|"  '{print $2}'`
        echo -e "subnetId:$subnetId \n"
        fi        
        } &
    done
    wait
done
neutron quota-update --network $networkQuota --subnet $subnetQuota --port $portQuota --tenant-id $OS_PROJECT_NAME >/dev/null
echo -e "well done! \n"

