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
# begin create network&&subnet

tenantId=`openstack project list | grep $OS_PROJECT_NAME | awk -F"|" '{print $2}'`
IPStart=10
IPStart_b=100
# the concurrent number of network creation
concurrent_number=5
# cycle number of concurrent operation
cycle_number=3
# external net
ext_net="ext-net"

# old  quota value
networkQuota=`neutron quota-show $tenantId | grep -w network | awk -F"|" '{print $3}'`
subnetQuota=`neutron quota-show $tenantId | grep -w subnet | awk -F"|" '{print $3}'`
portQuota=`neutron quota-show $tenantId | grep -w port | awk -F"|" '{print $3}'`
routerQuota=`neutron quota-show $tenantId | grep -w router | awk -F"|" '{print $3}'`
echo -e "odl Quota:\n"
echo -e "networkQuota:$networkQuota\n"
echo -e "subnetQuota:$subnetQuota\n"
echo -e "portQuota:$portQuota\n"
echo -e "routerQuota:$routerQuota\n"

# update new quota
echo -e "new update quota:\n"
neutron quota-update --network 50 --subnet 100 --port 400 --router 50 --tenant-id $tenantId

for ((j=1; j<=$cycle_number; j=j+1))
do
    for((i=1; i<=$concurrent_number; i=i+1))
    do
        IPStart=$[IPStart+1]
        IPStart_b=$[IPStart_b+1]
        {
        # create network1 for ipsec-vpn
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
        
        # get the id of the external net
        ext_net_id=`neutron net-list |grep -w "$ext_net" | awk '{print $2}' | grep -v '^$'`
        
        # create router
        router_id=`neutron router-create "router-$j-$i" |grep -w id | awk '{print$4}' |grep -v '^$'`
        sleep 2
        echo -e "router:$router_id"
        # binding network
        neutron router-interface-add $router_id $subnetId >/dev/null
        sleep 3
        # set gateway
        temp=`neutron router-gateway-set $router_id $ext_net_id`
        sleep 3
        neutron router-show $router_id >/dev/null
        
        # create network2 and router2 for ipsec-vpn 
        # create network
        neutron net-create --admin-state-up "$OS_PROJECT_NAME-net-b-$j-$i" >/dev/null
        sleep 3
        netId_b=`neutron net-list | grep "$OS_PROJECT_NAME-net-b-$j-$i" | awk -F "|"  '{print $2}'`

        if [ -n "$netId_b" ];then
        echo -e "netId:$netId_b \n"
        # create subnet
        neutron subnet-create \
--gateway 192.168.$IPStart_b.1 --allocation-pool start=192.168.$IPStart_b.10,end=192.168.$IPStart_b.100 \
--dns-nameserver 10.19.8.10 --enable-dhcp \
--ip-version 4 --name $OS_PROJECT_NAME-subnet-b-$IPStart_b $netId_b 192.168.$IPStart_b.0/24 >/dev/null
        sleep 5
        subnetId_b=`neutron subnet-list | grep "$OS_PROJECT_NAME-subnet-b-$IPStart_b" | awk -F "|" '{print $2}'`
        echo -e "subnetId:$subnetId_b \n"
        fi

        # get the id of the external net
        ext_net_id=`neutron net-list |grep -w "$ext_net" | awk '{print $2}' | grep -v '^$'`

        # create router
        router_id_b=`neutron router-create "router-b-$j-$i" |grep -w id | awk '{print$4}' |grep -v '^$'`
        sleep 2
        echo -e "router:$router_id_b"
        # binding network
        neutron router-interface-add $router_id_b $subnetId_b >/dev/null
        sleep 2
        # set gateway
        temp=`neutron router-gateway-set $router_id_b $ext_net_id`
        sleep 2
        neutron router-show $router_id_b >/dev/null
        
        # create ike-a &ipsec-a
        ikepolicy_id_a=`neutron vpn-ikepolicy-create "ikepolicy_a-$j-$i" |grep -w id |awk '{print$4}' |grep -v '^$'`
        ipsecpolicy_id_a=`neutron vpn-ipsecpolicy-create "ipsecpolicy_a-$j-$i" |grep -w id |awk '{print$4}' |grep -v '^$'`
        # create vpnservice_a
        neutron vpn-service-create --name "vpnservice_a-$j-$i" $router_id $subnetId >/dev/null
        sleep 10
        vpnserver_a=`neutron vpn-service-list |grep "vpnservice_a-$j-$i" |grep "$router_id" |awk '{print$2}' |grep -v '^$'`
        echo -e "vpnserver:$vpnserver_a for router:$router_id\n"
        # get the peer address,in fact ,it's the gateway of router_b and subnet_b
        peer_gw_router_b=`neutron router-list |grep "$router_id_b" |awk -F'"' '{print$16}' |grep -v '^$'`
        peer_cidr_a=`neutron subnet-list |grep "$subnetId_b" |awk '{print$6}' |grep -v '^$'` 
        sleep 2
        echo -e "peer_cidr-a:$peer_cidr_a \n"
        # create ipsec-site-connection_a
        neutron ipsec-site-connection-create --name "ipsec-site-connection_a-$j-$i" \
--vpnservice-id $vpnserver_a \
--ikepolicy-id $ikepolicy_id_a \
--ipsecpolicy-id $ipsecpolicy_id_a \
--peer-address $peer_gw_router_b  --peer-id $peer_gw_router_b \
--peer-cidr $peer_cidr_a  --psk "secret" >/dev/null
        sleep 20 
        # create ike-b &ipsec-b
        ikepolicy_id_b=`neutron vpn-ikepolicy-create "ikepolicy_b-$j-$i" |grep -w id |awk '{print$4}' |grep -v '^$'`
        ipsecpolicy_id_b=`neutron vpn-ipsecpolicy-create "ipsecpolicy_b-$j-$i" |grep -w id |awk '{print$4}' |grep -v '^$'`
        # create vpnservice_b
        neutron vpn-service-create --name "vpnservice_b-$j-$i" $router_id_b $subnetId_b >/dev/null
        sleep 10
        vpnserver_b=`neutron vpn-service-list |grep "vpnservice_b-$j-$i" |grep "$router_id_b" |awk '{print$2}' |grep -v '^$'`
        echo -e "vpnserver:$vpnserver_b for router:$router_id_b\n"
        
        # get the peer address,in fact ,it's the gateway of router_a and subnet_a
        peer_gw_router_a=`neutron router-list |grep "$router_id" |awk -F'"' '{print$16}' |grep -v '^$'`
        peer_cidr_b=`neutron subnet-list |grep "$subnetId" |awk '{print$6}' |grep -v '^$'`
        echo -e "peer_cidr_b:$peer_cidr_b \n"
        sleep 2
        # create ipsec-site-connection_b
        neutron ipsec-site-connection-create --name "ipsec-site-connection_b-$j-$i" \
--vpnservice-id $vpnserver_b \
--ikepolicy-id $ikepolicy_id_b \
--ipsecpolicy-id $ipsecpolicy_id_b \
--peer-address $peer_gw_router_a  --peer-id $peer_gw_router_a \
--peer-cidr $peer_cidr_b  --psk "secret" >/dev/null
        sleep 20
        echo -e "ipsec-vpn create! \n"
        # get the state of vpnservice
        vpn_state_a=`neutron vpn-service-list |grep "$vpnserver_a" |awk '{print$8}' |grep -v '^$'`
        sleep 5
        vpn_state_b=`neutron vpn-service-list |grep "$vpnserver_b" |awk '{print$8}' |grep -v '^$'`
        sleep 5
        # get the state of ipsec-site-connection
        connection_a=`neutron ipsec-site-connection-list |grep "ipsec-site-connection_a-$j-$i" |awk '{print$10}' |grep -v '^$'`
        sleep 5
        connection_b=`neutron ipsec-site-connection-list |grep "ipsec-site-connection_b-$j-$i" |awk '{print$10}' |grep -v '^$'`
        sleep 5 
        if [ $connection_b = "ACTIVE" -a $connection_a = "ACTIVE" -a $vpn_state_b = "ACTIVE" -a $vpn_state_a = "ACTIVE" ]; then
            echo -e "ipsec-vpn state:$vpn_state_a-$vpn_state_b-$connection_a-$connection_b \n"
            echo -e "ipsec-vpn-$j-$i function is ok"
        else
            echo -e "ipsec-vpn state:$vpn_state_a-$vpn_state_b-$connection_a-$connection_b \n"
            echo -e "ipsec-vpn-$j-$i function is error!!!\n"
        fi
        } &
    done
    sleep 5
    wait
done
neutron quota-update --network $networkQuota --subnet $subnetQuota --port $portQuota --router $routerQuota --tenant-id $OS_PROJECT_NAME >/dev/null
echo -e "well done! \n"

