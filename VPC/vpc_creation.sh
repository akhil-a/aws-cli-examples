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

#creates subnets
create_subnet(){
    name=$1
    vpc_id=$2
    cidr=$3
    az=$4
    tag_values=$(pass_tags subnet ${name})
    subnet_command=$(aws ec2 create-subnet --vpc-id "${vpc_id}" --cidr-block "${cidr}" --availability-zone "${az}" --tag-specifications "${tag_values}")
    check_command_success
    subnet_id=$(echo "$subnet_command" | jq -r '.Subnet.SubnetId')
    check_empty $subnet_id
    echo "$subnet_id"
}


##MAIN SECTION
#CREATE VPC HERE
echo "####################################################################################################"
echo "VPC Creation Script Started"
echo -e "####################################################################################################\n"
vpc_name="myVPC"
vpc_cidr="172.16.0.0/16"
echo "Creating VPC"
vpc_command=$(aws ec2 create-vpc --instance-tenancy "default" --cidr-block "${vpc_cidr}" --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=${vpc_name}}]" | jq )
check_command_success
vpc_id=$(echo $vpc_command | jq | grep "VpcId" | cut -d '"' -f 4)
check_empty $vpc_id
echo "VPC Created ${vpc_name} ${vpc_id}"
#vpc_id=""

#CREATE SUBNETS HERE
subnets_values="publicSubnet1,172.16.0.0/18,ap-south-1a
publicSubnet2,172.16.64.0/18,ap-south-1b
privateSubnet1,172.16.128.0/18,ap-south-1a
privateSubnet2,172.16.192.0/18,ap-south-1b"

while IFS=',' read -r subname subcidr subregion; do
    echo -e "Creating Subnet \nSubnet Name: $subname Region: $subregion Availability Zone: ${subregion}"
    subnet_id=$(create_subnet "$subname" "$vpc_id" "$subcidr" "$subregion")
    declare "${subname}_ID=$subnet_id"

done <<< "$subnets_values"
echo "publicSubnet1 ID: ${publicSubnet1_ID}"
echo "publicSubnet2 ID: ${publicSubnet2_ID}"
echo "privateSubnet1 ID: ${privateSubnet1_ID}"
echo "privateSubnet2 ID: ${privateSubnet2_ID}"

#CREATE IGW and attach to VPC here
echo "creating IGW"
igw=$(aws ec2 create-internet-gateway --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=vpcIGW},{Key=Environment,Value=PROD}]')
check_command_success
igwID=$(echo ${igw} | jq . | grep "InternetGatewayId" | cut -d '"' -f 4)
check_empty $igwID
echo -e " Created Internet Gateway ${igwID}. \nAttaching it to VPC"
aws ec2 attach-internet-gateway --internet-gateway-id ${igwID} --vpc-id ${vpc_id}
check_command_success

#CREATE NAT GateWay
echo "Creating elastic IP for NAT GW"
ipallocate=$(aws ec2 allocate-address --domain vpc)
elasticIP=$(echo $ipallocate | jq . | grep "AllocationId" | cut -d '"' -f 4)
check_empty $elasticIP

echo "Creating NAT GW in public subnet ${publicSubnet1_ID}"
nat_command=$(aws ec2 create-nat-gateway --subnet-id ${publicSubnet1_ID} --allocation-id ${elasticIP}  \
    --tag-specifications 'ResourceType=natgateway,Tags=[{Key=Name,Value=myNATGateway},{Key=Environment,Value=PROD}]')
check_command_success
echo "Waiting 2 minutes for NAT to come online"
sleep 140
natID=$(echo ${nat_command} | jq . | grep "NatGatewayId" | cut -d '"' -f 4)
check_empty $natID
echo "Created NAT Gateway ${natID}"

#ROUTE TABLE CREATION HERE
echo "Creating private route table"
privateroute=$(aws ec2 create-route-table --vpc-id ${vpc_id} \
    --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=PrivateRouteTable},{Key=Environment,Value=PROD}]')
check_command_success
privaterouteID=$(echo ${privateroute} | jq . | grep "RouteTableId" | cut -d '"' -f 4)
check_empty $privaterouteID
echo -e "Created Private Route table ${privaterouteID} \nAdding Rule"
aws ec2 create-route --route-table-id ${privaterouteID} --destination-cidr-block 0.0.0.0/0 --nat-gateway-id ${natID}
check_command_success
echo "Associating route table ${privaterouteID} with subnets ${privateSubnet1_ID} and ${privateSubnet2_ID}"
aws ec2 associate-route-table --subnet-id ${privateSubnet1_ID} --route-table-id ${privaterouteID}
check_command_success
aws ec2 associate-route-table --subnet-id ${privateSubnet2_ID} --route-table-id ${privaterouteID}
check_command_success



echo "Creating public route table"
publicroute=$(aws ec2 create-route-table --vpc-id ${vpc_id} \
    --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=PublicRouteTable},{Key=Environment,Value=PROD}]')
check_command_success
publicrouteID=$(echo ${publicroute} | jq . | grep "RouteTableId" | cut -d '"' -f 4)
check_empty $publicrouteID
echo -e "Created Public Route table ${publicrouteID} \nAdding Rule"
aws ec2 create-route --route-table-id ${publicrouteID} --destination-cidr-block 0.0.0.0/0 --gateway-id ${igwID}
check_command_success
echo "Associating route table ${publicrouteID} with subnets ${publicSubnet1_ID} and ${publicSubnet2_ID}"
aws ec2 associate-route-table --subnet-id ${publicSubnet1_ID} --route-table-id ${publicrouteID}
check_command_success
aws ec2 associate-route-table --subnet-id ${publicSubnet2_ID} --route-table-id ${publicrouteID}
check_command_success

echo "####################################################################################################"
echo "Script Completed Successfully :)"
echo -e "####################################################################################################\n"

echo -e "VPC : \n  VPC Name     :   ${vpc_name}\n  VPC Id       :   $vpc_id\n  VPC CIDR     :   $vpc_cidr"
echo -e "\nSubnets : "
while IFS=',' read -r subname subcidr subregion; do
    var="${subname}_ID"
    echo -e "    $subname   ${!var}     $subcidr    $subregion" 

done <<< "$subnets_values"

echo -e "\nInternet Gateway : \n  Id    :   ${igwID}"

echo -e "\nNATGateway : \n  Id     :    ${natID}"

echo -e "\nRoute Table : \n  Public Route Table      :   ${publicrouteID}\n  Private Route Table     :   ${privaterouteID}"
