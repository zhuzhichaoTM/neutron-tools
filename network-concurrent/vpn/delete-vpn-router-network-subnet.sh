#!/bin/bash
#  delete operation of vpn router network subnet
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
project_name_admin=true

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

# get tenant_id for "OS_PROJECT_NAME"
tenantId=`openstack project list | grep "$OS_PROJECT_NAME" |awk '{print$2}' | grep -v '^$'`
echo -e "tenantId:$tenantId"

# begin delete ipse-site-connection
connection_id_list=`neutron ipsec-site-connection-list | awk '{print $2}' | grep -iv id | grep -v '^$'`

# get ipse-site-connection belog to tenant
con_in_tenant_list=()
length_n=0
for id in $connection_id_list;
do
    tmp_tenant_id=`neutron ipsec-site-connection-show "$id" |grep -w tenant_id |awk '{print$4}' | grep -v '^$'`
    if [ $tmp_tenant_id = $tenantId ]; then
        con_in_tenant_list["$length_n"]=$id
        length_n=$[length_n+1]
    fi
done
echo -e "the tenant:$tenantId contain ipsec-site-connection:\n"
echo -e "${con_in_tenant_list[*]} "

# beginning to delete ipse-vpn
for con_id in ${con_in_tenant_list[*]};
do
    # get the vpnservice ike and ipsec of this ipsec-site-connection
    echo -e "ipsec-site-connection:$con_id \n"
    vpnservice_id=`neutron ipsec-site-connection-show $con_id |grep -w vpnservice_id |awk '{print$4}' | grep -v '^$'`
    ipsec_id=`neutron ipsec-site-connection-show $con_id |grep -w ipsecpolicy_id |awk '{print$4}' | grep -v '^$'`
    ike_id=`neutron ipsec-site-connection-show $con_id |grep -w ikepolicy_id |awk '{print$4}' | grep -v '^$'`
    # clear ipsec-site-connection
    neutron ipsec-site-connection-delete $con_id >/dev/null
    echo -e "delete ipsec-site-connection:$con_id \n"
    # clear vpnservice
    neutron vpn-service-delete $vpnservice_id >/dev/null
    echo -e "delete vpnservice:$vpnservice_id \n"
    # clear ipsec
    ipsec_delete_id=`neutron vpn-ipsecpolicy-list |grep "$ipsec_id" |awk '{print$2}' |grep -v '^$'`
    if [ -n $ipsec_delete_id ]; then
        neutron	vpn-ipsecpolicy-delete $ipsec_delete_id >/dev/null
        echo -e "delete ipsecpolicy:$ipsec_delete_id \n"
    fi
    # clear ike
    ike_delete_id=`neutron vpn-ikepolicy-list |grep "$ike_id" |awk '{print$2}' |grep -v '^$'`
    if [ -n $ipsec_delete_id ]; then
        neutron vpn-ikepolicy-delete $ike_delete_id >/dev/null
        echo -e "delete ikepolicy:$ike_delete_id \n"
    fi
done

# clear residual vpnservice
residual_vpnservice=`neutron vpn-service-list | awk '{print $2}' | grep -iv id | grep -v '^$'`
for vpn_id in $residual_vpnservice;
do
    tmp_id=`neutron vpn-service-show "$vpn_id" |grep -w tenant_id |awk '{print$4}' | grep -v '^$'`
    if [ $tmp_id = $tenantId ]; then
        neutron vpn-service-delete $vpn_id >/dev/null
    fi
done

# clear residual ipsec
residual_ipsec=`neutron vpn-ipsecpolicy-list | awk '{print $2}' | grep -iv id | grep -v '^$'`
for re_ipsec_id in $residual_ipsec;
do
    tmp_id=`neutron vpn-ipsecpolicy-show "$re_ipsec_id" |grep -w tenant_id |awk '{print$4}' | grep -v '^$'`
    if [ $tmp_id = $tenantId ]; then
        echo -e "residual ipsec:$re_ipsec_id belong to $tmp_id"
        neutron vpn-ipsecpolicy-delete $re_ipsec_id >/dev/null
    fi
done

# clear residual ike
residual_ike=`neutron vpn-ikepolicy-list | awk '{print $2}' | grep -iv id | grep -v '^$'`
for re_ike_id in $residual_ike;
do
    tmp_id=`neutron vpn-ikepolicy-show "$re_ike_id" |grep -w tenant_id |awk '{print$4}' | grep -v '^$'`
    if [ $tmp_id = $tenantId ]; then
        echo -e "residual ike :$re_ike_id belong to $tmp_id"
        neutron vpn-ikepolicy-delete $re_ike_id >/dev/null
    fi
done
echo -e "well done! delete all the ipsec-vpn-connection\n"

# begin delete router
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

# beginning to delete router
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

# beginning to delete net subnet port
for net_id in ${net_in_tenant_list[*]};
do
    subnet_in_tenant_list=`neutron net-list |grep $net_id |awk '{print$6}' | grep -v '^$'`
    for subnet_id in $subnet_in_tenant_list;
    do
        port_in_tenant_list=`neutron port-list |grep "$subnet_id" |awk '{print$2}' | grep -v '^$'`
        echo -e "port:$port_in_tenant_list\n"
        for port_id in $port_in_tenant_list;
        do
            neutron port-delete "$port_id" >/dev/null
        done
        neutron subnet-delete "$subnet_id" >/dev/null
        sleep 2
        echo -e "delete subnet_id:$subnet_id\n"
    done
    neutron net-delete "$net_id" > /dev/null
    echo -e "delete net_id:$net_id\n" 
done
echo -e "well done! delete all the network \n"
echo -e "well done!\n"
