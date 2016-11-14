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

