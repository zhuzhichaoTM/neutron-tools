#!/bin/bash

export NEUTRON="neutron.sh"



function neutron_ipsec_vpn_create() {
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
            echo -e "ipsec-vpn-$j-$i:ipsec_vpn create sucess!!! \n"
        else
            echo -e "ipsec-vpn state:$vpn_state_a-$vpn_state_b-$connection_a-$connection_b \n"
            echo -e "ipsec-vpn-$j-$i function is error!!!\n"
        fi
}

function neutron_ipsec_vpn_delete() {
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
}

function neutron_floatingip_create() {
    #create floatingip
 
    # create vm
    flavor=`nova flavor-list | grep True | awk -F "|"  'NR==1{print $3}'`
    image=`nova image-list | grep ACTIVE | awk -F "|"  'NR==1{print $3}'`
    # del space
    netId_nova=${netId:1:36}
    echo -e "create vm $OS_PROJECT_NAME-ins-$j-$i "
    nova boot "$OS_PROJECT_NAME-ins-$j-$i" --flavor $flavor --image $image --nic net-id=$netId_nova >/dev/null
    sleep 5

    # get the id of the external net
    ext_net_id=`neutron net-list |grep -w "$ext_net" | awk '{print $2}' | grep -v '^$'`
        
    # create and bind float ip
    floatip=`neutron floatingip-create $ext_net_id | awk -F "|"  'NR==7{print $3}'`
    sleep 2
    echo -e "$OS_PROJECT_NAME-ins-$j-$i bind floating-ip $floatip"
    nova floating-ip-associate "$OS_PROJECT_NAME-ins-$j-$i" $floatip >/dev/null
    sleep 2   
    echo -e "$OS_PROJECT_NAME-ins-$j-$i unbind floating-ip $floatip"
    nova floating-ip-disassociate "$OS_PROJECT_NAME-ins-$j-$i" $floatip >/dev/null     
    sleep 2
    floatip2=`neutron floatingip-create $ext_net_id | awk -F "|"  'NR==7{print $3}'`
    sleep 2
    echo -e "$OS_PROJECT_NAME-ins-$j-$i bind new floating-ip $floatip2"
    nova floating-ip-associate "$OS_PROJECT_NAME-ins-$j-$i" $floatip2 >/dev/null
    floatid=`neutron floatingip-list |grep $floatip |awk '{print$2}' | grep -v '^$'`
    neutron floatingip-delete $floatid >/dev/null    
    echo -e "$floatip&&$floatip2:floatingip create success!!!\n"
}

function neutron_floatingip_delete() {
    # delete all the floatingips
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

    # delete vm
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

    # delete the floatingip
    floatingips=`neutron floatingip-list | awk '{print $2}' | grep -iv ID | grep -v '^$'`
    floatingip_in_tenant_list=()
    length_n=0
    for id in $floatingips;
    do
        tmp_tenant_id=`neutron floatingip-show "$id" |grep -w tenant_id | awk '{print $4}' | grep -v '^$'`
        if [ $tmp_tenant_id = $tenantId ]; then
            floatingip_in_tenant_list["$length_n"]=$id
            length_n=$[length_n+1]
        fi
    done
    for floatingip_id in ${floatingip_in_tenant_list[*]};
    do
        neutron floatingip-delete $floatingip_id >/dev/null
    done

}

function neutron_fw_create() {
    #create fw policy, rule, then bind router
    fw_policy_1=`neutron firewall-policy-create "fw-policy-$j-$j-1" |grep -w id | awk '{print$4}' |grep -v '^$'`
    fw_policy_2=`neutron firewall-policy-create "fw-policy-$j-$j-2" |grep -w id | awk '{print$4}' |grep -v '^$'`
    fw_rule_1=`neutron firewall-rule-create --name "fw-rule-$j-$i-1" --protocol tcp  --action allow |grep -w id | awk '{print$4}' |grep -v '^$'`
    fw_rule_2=`neutron firewall-rule-create --name "fw-rule-$j-$i-2" --protocol tcp  --action allow |grep -w id | awk '{print$4}' |grep -v '^$'`
    sleep 2
    neutron firewall-policy-insert-rule "$fw_policy_1" "$fw_rule_1" >/dev/null
    neutron firewall-policy-insert-rule "$fw_policy_2" "$fw_rule_2" >/dev/null
    sleep 2
    neutron firewall-create --name "fw-firewall-$j-$i-1" --router "router-$j-$i" "fw-policy-$j-$i-1" >/dev/null
    neutron firewall-delete "fw-firewall-$j-$i-1" >/dev/null
    neutron firewall-create --name "fw-firewall-$j-$i-2" --router "router-$j-$i" "fw-policy-$j-$i-2" >/dev/null
    echo -e "fw-firewall-$j-$i-1 && fw-firewall-$j-$i-2:firewall create success!!!\n"
}

function neutron_fw_delete() {
    #delete firewall policy, rule, firewall

    #delete fw
    firewalls=`neutron firewall-list | grep fw-firewall | awk -F'|' '{print $2}' | grep -v '^$'`	
    fw_in_tenant_list=()
    length_n=0
    for id in $firewalls;
    do
        tmp_tenant_id=`neutron firewall-show "$id" |grep -w tenant_id | awk '{print $4}' | grep -v '^$'`
        if [ $tmp_tenant_id = $tenantId ]; then
            fw_in_tenant_list["$length_n"]=$id
            length_n=$[length_n+1]
        fi
    done
    for firewall_id in ${fw_in_tenant_list[*]};
    do
        neutron firewall-delete $firewall_id >/dev/null
    done

    #delete policy in fw
    fw_policys=`neutron firewall-policy-list | grep fw-policy | awk -F'|' '{print $2}' | grep -v '^$'`
    fw_policy_in_tenant_list=()
    length_n=0
    for id in $fw_policys;
    do
        tmp_tenant_id=`neutron firewall-policy-show "$id" |grep -w tenant_id | awk '{print $4}' | grep -v '^$'`
        if [ $tmp_tenant_id = $tenantId ]; then
            fw_policy_in_tenant_list["$length_n"]=$id
            length_n=$[length_n+1]
        fi
    done
    for fw_policy_id in ${fw_policy_in_tenant_list[*]};
    do
        neutron firewall-policy-delete $fw_policy_id >/dev/null
    done

    #firewall policy depend on firewall rule, so firewall should be deleted first
    fw_rules=`neutron firewall-rule-list | grep fw-rule | awk -F'|' '{print $2}' | grep -v '^$'`
    fw_rule_in_tenant_list=()
    length_n=0
    for id in $fw_rules;
    do              
        tmp_tenant_id=`neutron firewall-rule-show "$id" |grep -w tenant_id | awk '{print $4}' | grep -v '^$'`
        if [ $tmp_tenant_id = $tenantId ]; then
            fw_rule_in_tenant_list["$length_n"]=$id
            length_n=$[length_n+1]
        fi  
    done    
    for fw_rule_id in ${fw_rule_in_tenant_list[*]};
    do
        neutron firewall-rule-delete $fw_rule_id >/dev/null
    done
    echo -e "delete all the fws!!\n"    
}

function neutron_network_subnet_port_create() {
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
    echo -e "$OS_PROJECT_NAME-net-$j-$i:net create success!!!\n"
}

function neutron_network_subnet_port_delete() {
    # begin delete network subnet and port
    tenantId=`openstack project list | grep "$OS_PROJECT_NAME" |awk '{print$2}' | grep -v '^$'`
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
    echo -e "delete all the net subnet port success!!\n"
}

function neutron_router_create() {
    # create router
    # get the id of the external net
    ext_net_id=`neutron net-list |grep -w "$ext_net" | awk '{print $2}' | grep -v '^$'`

    # create router
    router_id=`neutron router-create "router-$j-$i" |grep -w id | awk '{print$4}' |grep -v '^$'`
    echo -e "router:$router_id"
    # binding network
    neutron router-interface-add $router_id $subnetId >/dev/null
    # set gateway
    temp=`neutron router-gateway-set $router_id $ext_net_id`
    neutron router-show $router_id >/dev/null
    echo -e "router-$j-$i:router create success!!!\n"
}

function neutron_router_delete() {
    # delete router
    tenantId=`openstack project list | grep "$OS_PROJECT_NAME" |awk '{print$2}' | grep -v '^$'`
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
        neutron router-gateway-clear $router_id >/dev/null
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
}

function neutron-openrc-create() {
    # create openrc
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
}

function neutron-quota-update() {
    # update quota for special test
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
}
