#!/bin/bash
#  delete operation of network subnet and port
#
#
# the operations execute within a general tenant or advanced tenant   
#  
# 
# history:
# 2016/11/14
# author zoushl@fiberhome.com
path=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export path
echo -e "Now the shell is beginning! "

# please change them according to your openstack environment
# use admin project
source_file_path="/root"
openrc_name="admin-openrc"

# use private tenant project
# please change them according to your tenant info
tenant_openrc_name="zsl_prj-openrc.sh"
OS_PROJECT_NAME="zsl_prj"
OS_TENANT_NAME="zsl_prj"
OS_USERNAME="zsl"
OS_PASSWORD="1"

# default set false that means you choose your private tenant
# set true that means you choose admin tenant
project_name_admin=false

if $project_name_admin ; then
    source $source_file_path/$openrc_name
    echo -e "Now the shell is beginning in $openrc_name! "
else
    if [ -f "$source_file_path/$tenant_openrc_name" ]; then
        echo "the zsl_prj-openrc.sh exists"
    else
        echo "copy the admin-openrc"
        cp $source_file_path/$openrc_name $source_file_path/$tenant_openrc_name
        sed -i -e "3cexport OS_PROJECT_NAME=$OS_PROJECT_NAME" $source_file_path/$tenant_openrc_name
        sed -i -e "4cexport OS_TENANT_NAME=$OS_TENANT_NAME" $source_file_path/$tenant_openrc_name
        sed -i -e "5cexport OS_USERNAME=$OS_USERNAME" $source_file_path/$tenant_openrc_name
        sed -i -e "6cexport OS_PASSWORD=$OS_PASSWORD" $source_file_path/$tenant_openrc_name
    fi
    source $source_file_path/$tenant_openrc_name
    echo -e "Now the shell is beginning in $tenant_openrc_name! "
fi
# begin delete network subnet and port

#tenantId=`openstack project list | grep "$OS_PROJECT_NAME" |awk '{print $2}' | grep -v '^$'`
tenantId=`openstack project list | grep $OS_PROJECT_NAME | awk -F"|" '{print $2}'`
echo -e "tenantId:$tenantId"

# get vm belong to tenant
nova_list=`nova list | awk '{print $2}' | grep -iv ID | grep -v '^$'`
nova_in_tenant_list=()
length_n=0
for id in $nova_list;
do
    tmp_tenant_id=`nova show "$id" |grep -w tenant_id | awk '{print $4}' | grep -v '^$'`
    if [ $tmp_tenant_id = $tenantId ]; then
        nova_in_tenant_list["$length_n"]=$id
        length_n=$[length_n+1]
    fi 
done

echo -e "the tenant:$tenantId contain vms:"
echo -e "${nova_in_tenant_list[*]} "

for nova_id in ${nova_in_tenant_list[*]};
do
    floatip=`nova floating-ip-list |grep "$nova_id" |awk '{print$4}' | grep -v '^$'`
    floatid=`nova floating-ip-list |grep "$nova_id" |awk '{print$2}' | grep -v '^$'`
    if [ -n "$floatid" ];then
        nova floating-ip-disassociate "$nova_id" $floatip >/dev/null
        neutron floatingip-delete $floatid >/dev/null
        echo -e "delete floating-ip:$floatip"
    fi
    nova delete $nova_id >/dev/null
    echo -e "delete nova_id:$nova_id"
done


# get router belog to tenant
router_list=`neutron router-list | awk '{print $2}' | grep -iv id | grep -v '^$'`
router_in_tenant_list=()

length_n=0
for id in $router_list;
do
    tmp_tenant_id=`neutron router-show "$id" |grep -w tenant_id | awk '{print $4}' | grep -v '^$'`
    if [ $tmp_tenant_id = $tenantId ]; then
        router_in_tenant_list["$length_n"]=$id
        length_n=$[length_n+1]
    fi 
done

echo -e "the tenant:$tenantId contain router:"
echo -e "${router_in_tenant_list[*]} "

for router_id in ${router_in_tenant_list[*]};
do
    neutron router-gateway-clear $router_id > /dev/null
    subnet_id_src=`neutron router-port-list $router_id | awk '{print $8}'| grep -iv fixed_ips \
            | grep -v '^$' |  awk -F ","  '{print $1}' `
    # delete ""    
    subnet_id=${subnet_id_src:1:36}
    echo -e "delete interface: routerid:$router_id, subnet_id:$subnet_id"
    neutron router-interface-delete $router_id $subnet_id > /dev/null
    neutron router-delete $router_id > /dev/null
    echo -e "delete router_id:$router_id" 
done

net_list=`neutron net-list | awk '{print $2}' | grep -iv id | grep -v '^$'`
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

echo -e "the tenant:$tenantId contain network:"
echo -e "${net_in_tenant_list[*]} "

for net_id in ${net_in_tenant_list[*]};
do
    subnet_in_tenant_list=`neutron net-list |grep "$net_id" |awk '{print$6}' | grep -v '^$'`
    for subnet_id in $subnet_in_tenant_list;
    do
        port_in_tenant_list=`neutron port-list |grep "$subnet_id" |awk '{print$2}' | grep -v '^$'`
        echo -e "port:$port_in_tenant_list"
        for port_id in $port_in_tenant_list;
        do
            neutron port-delete "$port_id" >/dev/null      
        done
        neutron subnet-delete "$subnet_id" >/dev/null
        echo -e "delete subnet_id:$subnet_id"
    done
    neutron net-delete "$net_id" > /dev/null
    echo -e "delete net_id:$net_id" 
done


echo -e "well done! "
