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

tenantId=`openstack project list | grep $OS_PROJECT_NAME | awk -F"|" '{print $2}'`
#echo $tenantId

IPStart=10
# the concurrent number of network creation
concurrent_number=3
# cycle number of concurrent operation
cycle_number=3

# old  quota value
networkQuota=`neutron quota-show $tenantId | grep -w network | awk -F"|" '{print $3}'`
subnetQuota=`neutron quota-show $tenantId | grep -w subnet | awk -F"|" '{print $3}'`
portQuota=`neutron quota-show $tenantId | grep -w port | awk -F"|" '{print $3}'`
routerQuota=`neutron quota-show $tenantId | grep -w router | awk -F"|" '{print $3}'`
floatingipQuota=`neutron quota-show $tenantId | grep -w floatingip | awk -F"|" '{print $3}'`
#echo -e "odl Quota:\n"
#echo -e "networkQuota:$networkQuota\n"
#echo -e "subnetQuota:$subnetQuota\n"
#echo -e "portQuota:$portQuota\n"

# update new quota
#echo -e "new update quota:\n"
neutron quota-update --network 50 --subnet 100 --port 400 --router 100 \
                     --floatingip 100  --tenant-id $tenantId >/dev/null

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
        echo -e "netId:$netId "
        # create subnet
        neutron subnet-create \
        --gateway 192.168.$IPStart.1 --allocation-pool start=192.168.$IPStart.10,end=192.168.$IPStart.100 \
        --dns-nameserver 10.19.8.10 --enable-dhcp \
        --ip-version 4 --name $OS_PROJECT_NAME-subnet-$IPStart $netId 192.168.$IPStart.0/24 >/dev/null
        sleep 5
        subnetId=`neutron subnet-list | grep "$OS_PROJECT_NAME-subnet-$IPStart" | awk -F "|"  '{print $2}'`
        echo -e "subnetId:$subnetId "
        fi

        # create router
        neutron router-create "$OS_PROJECT_NAME-router-$j-$i" >/dev/null     
        routerId=`neutron router-list | grep "$OS_PROJECT_NAME-router-$j-$i" | awk -F "|"  '{print $2}'`
        echo -e "routerId:$routerId "
        sleep 2
        # create ext-net and subnet
        extnetId=`neutron net-create "extnet-$j-$i" --router:external --admin-state-up | awk -F "|" 'NR==10{print $3}'`
        extnetName="extnet-$j-$i"           
        echo -e "extnetId:$extnetId "   
        sleep 2      
        neutron subnet-create \
            --gateway 192.100.$IPStart.1 --allocation-pool start=192.100.$IPStart.10,end=192.100.$IPStart.100 \
            --dns-nameserver 10.19.8.10 --enable-dhcp \
            --ip-version 4 --name extsubnet $extnetId 192.100.$IPStart.0/24 >/dev/null
        sleep 2              
        # add interface                      
        neutron router-gateway-set $routerId $extnetId >/dev/null
        neutron router-interface-add $routerId $subnetId >/dev/null

        # create vm
        flavor=`nova flavor-list | grep True | awk -F "|"  'NR==1{print $3}'`
        image=`nova image-list | grep ACTIVE | awk -F "|"  'NR==1{print $3}'`
        # del space
        netId_nova=${netId:1:36}
        echo -e "create vm $OS_PROJECT_NAME-ins-$j-$i "
        nova boot "$OS_PROJECT_NAME-ins-$j-$i" --flavor $flavor --image $image --nic net-id=$netId_nova >/dev/null
        sleep 5
        # create and bind float ip
        floatip=`neutron floatingip-create $extnetName | awk -F "|"  'NR==7{print $3}'`
        sleep 2
        echo -e "$OS_PROJECT_NAME-ins-$j-$i bind floating-ip $floatip"
        nova floating-ip-associate "$OS_PROJECT_NAME-ins-$j-$i" $floatip >/dev/null
        sleep 2   
        echo -e "$OS_PROJECT_NAME-ins-$j-$i unbind floating-ip $floatip"
        nova floating-ip-disassociate "$OS_PROJECT_NAME-ins-$j-$i" $floatip >/dev/null     
        sleep 2
        floatip2=`neutron floatingip-create $extnetName | awk -F "|"  'NR==7{print $3}'`
        sleep 2
        echo -e "$OS_PROJECT_NAME-ins-$j-$i bind new floating-ip $floatip2"
        nova floating-ip-associate "$OS_PROJECT_NAME-ins-$j-$i" $floatip2 >/dev/null

        floatid=`neutron floatingip-list |grep $floatip |awk '{print$2}' | grep -v '^$'`
        neutron floatingip-delete $floatid >/dev/null

        } &
    done
    wait
done
neutron quota-update --network $networkQuota --subnet $subnetQuota --port $portQuota  \
        --router $routerQuota --floatingip $floatingipQuota --tenant-id $tenantId >/dev/null
echo -e "well done! "

