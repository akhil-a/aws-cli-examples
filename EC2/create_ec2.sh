#!/bin/bash
set -e

#Passes tag specification
pass_tags(){
    tags="ResourceType=$1,Tags=[{Key=Name,Value=$2},{Key=Environment,Value=PROD}]"
    echo $tags
}

#checks if prev command executed successfully
check_command_success() {
    if [ $? -ne 0 ]; then
        echo "Command Failed to create $1" >&2
        exit 1
    fi
}

#check if the ID is empty
check_empty() {
    local name="$1"
    if [ -z "$name" ] || [ "$name" == "null" ]; then
        echo "Failed to create $name . ID empty" >&2
        exit 1
    fi
}

echo "####################################################################################################"
echo "EC2 Creation Script Started"
echo -e "####################################################################################################\n"

cp -r ../VPC/vpc_details.var infra.var
source infra.var
echo "Create App Server 1"
app_server1=$(aws ec2 run-instances \
        --image-id ami-0d682f26195e9ec0f \
        --count 1 \
        --instance-type t2.micro \
        --key-name bastion \
        --security-group-ids ${webSG_ID} \
        --subnet-id ${privateSubnet1_ID} \
        --user-data file://userdata.sh \
        --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=app-server1},{Key=Environment,Value=PROD}]') 

check_command_success
app_server1_ID=$(echo $app_server1 | jq -r '.Instances[0].InstanceId')
check_empty $app_server1_ID

echo "Create App Server 2"
app_server2=$(aws ec2 run-instances \
        --image-id ami-0d682f26195e9ec0f \
        --count 1 \
        --instance-type t2.micro \
        --key-name bastion \
        --security-group-ids ${webSG_ID} \
        --subnet-id ${privateSubnet2_ID} \
        --user-data file://userdata.sh \
        --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=app-server2},{Key=Environment,Value=PROD}]') 

check_command_success
app_server2_ID=$(echo $app_server2 | jq -r '.Instances[0].InstanceId')
check_empty $app_server2_ID

echo "Create Bastion Host"
bastion=$(aws ec2 run-instances \
        --image-id ami-0d682f26195e9ec0f \
        --count 1 \
        --instance-type t2.micro \
        --key-name bastion \
        --security-group-ids ${bastionSG_ID} \
        --subnet-id ${publicSubnet2_ID} \
        --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=bastion-host},{Key=Environment,Value=PROD}]') 

check_command_success
bastion_ID=$(echo $bastion | jq -r '.Instances[0].InstanceId')
check_empty $bastion_ID

echo $app_server1  | jq . > app_server1_conf.json
echo $app_server2  | jq . > app_server2_conf.json
echo $bastion  | jq . > bastion_conf.json

echo "app_server1_ID=$app_server1_ID" >> infra.var
echo "app_server2_ID=$app_server2_ID" >> infra.var
echo "bastion_ID=$bastion_ID" >> infra.var

echo "####################################################################################################"
echo "EC2 Script Completed Successfully :)"
echo -e "####################################################################################################\n"

echo "App Server1 : $app_server1_ID"
echo "App Server2 : $app_server2_ID"
echo "Bastion : $bastion_ID"

