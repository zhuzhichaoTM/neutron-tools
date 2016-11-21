#!/usr/bin/env bash
#create a project and a user fo the project for testing

domain_name='default'
project_name=''
project_id=''
user_name=''
user_id=''
password="Abc12345"
ERROR=10
FILE='env_for_cleanup'  #save the env var needed by clean up resourse

#func to set name of one attr, etc project user
#use: setName attrName
function setName {
    local key=$1
	local value
    read -p "Enter the name of $1 to create: " value
    while [ -z $value ]
    do
		echo "You input nothing!"
		read -p "Enter the name of $1 to create: " value
	done
	echo $value
}

#func to create a project
function createProject {
	project_name=`setName "project"`
	echo "project $project_name is to create"
	project_id=`openstack project create --domain $domain_name $project_name|grep -w id |awk '{print $4}'`
	while test $? -ne 0
	do
		echo "The project exist! Choose a new name"
		project_name=`setName 'project'`
                project_id=`openstack project create --domain $domain_name $project_name|grep -w id |awk '{print $4}'`
	done
	echo "succeed to create project $project_name"
}

function setRole {
    role=$1
    openstack role add --project $project_name  --user $user_name $role
}

function createUser {
	user_name=`setName "user"`
	echo "user $user_name is to create"
	user_id=`openstack user create --domain $domain_name --project $project_name \
	--password $password $user_name |grep -w id |awk '{print $4}'`
	while [ $? -ne 0 ]
	do
		echo "The user exist! Choose a new name"
		user_name=`setName "user"`
		user_id=`openstack user create --domain $domain_name --project $project_name \
		--password $password $user_name |grep -w id |awk '{print $4}'`
	done
	echo "succeed to create user $user_name"
	setRole 'admin'  #set a role to the user
	echo "add a admin role to the user"
}
function createFile {
	local var=1
	local file_name=$1
#	cd /root/
	while [ -f $file_name ]
	do
		file_name=${file_name}${var}
		var=$[ $var + 1 ]
	done
	touch $file_name
	echo $file_name
}

function createOpenrcfile {
	local file_name=${user_name}_${project_name}_openrc
	createFile $file_name
#save the var into a file in order to clean up afterwards
	echo "openrc_file=$file_name" >>$FILE
#	cd /root/
	if [ -f openrc_template ]
	then
		cat openrc_template >$file_name
		sed -i "s/OS_PROJECT_NAME=/OS_PROJECT_NAME=$project_name/g" $file_name
		sed -i "s/OS_USERNAME=/OS_USERNAME=$user_name/g" $file_name
		sed -i "s/OS_PASSWORD=/OS_PASSWORD=$password/g" $file_name
	else
		echo "openrc_template does not exist"
		return $ERROR
	fi	
}

createProject
createUser
createOpenrcfile

echo "project_id=$project_id" >>$FILE
echo "user_id=$user_id">>$FILE

