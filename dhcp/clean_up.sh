#/bin/env bash
#clean up the resourse created to test

net_id=''
subnet_id=''
vm_name=''
count=''
openrc_file=''
FILE='env_for_cleanup'  #save the env var needed by clean up resourse

#init var need from a file to save these var
source $FILE
#get the openstack cloud auth message
source $openrc_file

user_name=$OS_USERNAME
case $user_name in 
'glance' | 'nova' |'neutron'|'cinder' )
    echo "dangerous to delete $user_name"
    exit 1;;
*)
    ;;
esac

project_name=$OS_PROJECT_NAME
case $project_name in
'admin' | 'service' | 'demo' )
    echo "dangerous to delete $project_name"
    exit 1;;
*)
    ;;
esac

#clean up the vm resource
#count=6
while [ $count -gt 1 ]
do
	nova delete ${vm_name}-${count}
	count=$[ $count - 1 ]
done

#clean up the network resource
neutron subnet-delete $subnet_id
neutron net-delete $net_id

#echo "would you want to delete the project and user you just create?(y or n)"
#read decision

#if [ $decision = 'y' ];then
#	openstack user delete $user_name
#	openstack project delete $project_name
#	echo "The project and user has been deleted"
#	rm $openrc_file
#	rm $FILE
#else
#	echo "The project and user still be there"
#	echo "You can use them to test afterwards"
#	echo "openrc_file=$openrc_file" > $FILE
#fi
