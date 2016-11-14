#!/bin/bash
#  delete operation of network subnet and port
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
# begin delete network subnet and port

tenantId=`openstack project list | grep "$OS_PROJECT_NAME" |awk '{print$2}' | grep -v '^$'`
echo -e "tenantId:$tenantId"
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
echo -e "well done! \n"
