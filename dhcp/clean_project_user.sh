#!/bin/env bash

openrc_file=''
FILE='env_for_cleanup'  #save the env var needed by clean up resourse

#init var need from a file to save these var
source $FILE
#get the openstack cloud auth message
source $openrc_file

if [ $? -ne 0 ]
then
    return $?
fi

user_name=$OS_USERNAME
project_name=$OS_PROJECT_NAME

case $user_name in
'glance' | 'nova' |'neutron'|'cinder' )
    echo "dangerous to delete $user_name"
    exit 1;;
*)
    ;;
esac

case $project_name in
'admin' | 'service' | 'demo' )
    echo "dangerous to delete $project_name"
    exit 1;;
*)
    ;;
esac

source /root/admin_openrc

openstack user delete $user_name
openstack project delete $project_name
echo "The project and user has been deleted"
rm $openrc_file
rm $FILE

