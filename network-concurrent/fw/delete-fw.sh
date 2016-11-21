#!/bin/bash -x
#  delete operation of router
#
#
# the operations execute within a general tenant or advanced tenant   
#  
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
. fw.sh

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
    OS_PROJECT_NAME="admin"
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
# begin delete router

tenantId=`openstack project list | grep -w "$OS_PROJECT_NAME" |awk '{print$2}' | grep -v '^$'`
echo -e "tenantId:$tenantId"
router_list=`neutron router-list | awk '{print $2}' | grep -iv id | grep -v '^$'`
# get router belog to tenant
router_in_tenant_list=()

length_n=0
for id in $router_list;
do
    tmp_tenant_id=`neutron router-show $id |grep -w tenant_id |awk '{print$4}' | grep -v '^$'`
    if [ $tmp_tenant_id = $tenantId ]; then
        router_in_tenant_list["$length_n"]=$id
        length_n=$[length_n+1]
    fi 
done

echo -e "the tenant:$tenantId contain router:\n"
echo -e "${router_in_tenant_list[*]} "

for router_id in ${router_in_tenant_list[*]};
do
    # clear the gateway of router
    echo -e "router:$router_id\n"
    neutron router-gateway-clear $router_id
    # get binding subnet
    subnet_id_bind_router=`neutron router-port-list $router_id | grep -w subnet_id | grep -iv HA | awk -F'"' '{print $4}'`
    # if router does not bind any subnet,delete router
    if [ -n $subnet_id_bind_router ]; then
        for subnet_id in $subnet_id_bind_router;
        do
            #remove bind with subnet
            neutron router-interface-delete $router_id $subnet_id >/dev/null
        done
    fi
    neutron router-delete $router_id >/dev/null
    echo -e "delete router:$router_id"
done
echo -e "well done! delete all the routers\n"

# begin delete network subnet and port

tenantId=`openstack project list | grep  -w "$OS_PROJECT_NAME" |awk '{print$2}' | grep -v '^$'`
echo -e "tenantId:$tenantId"
net_list=`neutron net-list |grep -iv "ext" | awk '{print $2}' | grep -iv id | grep -v '^$'`
# get net belog to tenant
net_in_tenant_list=()

length_n=0
for id in $net_list;
do
    tmp_tenant_id=`neutron net-show "$id" |grep -w tenant_id | awk '{print $4}' | grep -v '^$'`
    if [ $tmp_tenant_id = $tenantId ]; then
        net_in_tenant_list["$length_n"]=$id
        length_n=$[length_n+1]
    fi
done

echo -e "the tenant:$tenantId contain network:\n"
echo -e "${net_in_tenant_list[*]} "

for net_id in ${net_in_tenant_list[*]};
do
    subnet_in_tenant_list=`neutron net-list |grep "$net_id" |awk '{print$6}' | grep -v '^$'`
    for subnet_id in $subnet_in_tenant_list;
    do
        port_in_tenant_list=`neutron port-list |grep "$subnet_id" |awk '{print$2}' | grep -v '^$'`
        echo -e "port:$port_in_tenant_list\n"
        for port_id in $port_in_tenant_list;
        do
            neutron port-delete "$port_id" >/dev/null
        done
        neutron subnet-delete "$subnet_id" >/dev/null
        echo -e "delete subnet_id:$subnet_id\n"
    done
    neutron net-delete "$net_id" > /dev/null
    echo -e "delete net_id:$net_id\n" 
done
echo -e "well done! delete all the network \n"

fw_cleanup

echo -e "well don!\n"
