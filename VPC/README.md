# Amazon Virtual Private Cloud (VPC)

## Overview
With [Amazon Virtual Private Cloud (Amazon VPC)](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html), you can launch AWS resources in a logically isolated virtual network that you've defined. This virtual network closely resembles a traditional network that you'd operate in your own data center, with the benefits of using the scalable infrastructure of AWS.

### Creating a VPC
We can use `aws ec2 create-vpc` for creating VPC with 172.16.0.0/16 cidr. Its is a good practice to give meaningful name to the AWS resources, Lets call our VPC `myVPC`

```sh
aws ec2 create-vpc --instance-tenancy "default" \
  --cidr-block "172.16.0.0/16" \
  --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=myVPC}]"
```

Use the below command to Enable DNS hostname

```sh
aws ec2 modify-vpc-attribute --enable-dns-hostnames '{"Value":true}' --vpc-id vpc-04123a432bb674be6"
```

Use the command `aws ec2 create-subnet` to create **subnet**

```sh
aws ec2 create-subnet \
  --vpc-id "vpc-04123a432bb674be6" \
  --cidr-block "172.16.0.0/18" \
  --availability-zone "ap-south-1a" \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=publicSubnet1}]"
```

Use the command `aws ec2 modify-subnet-attribute` with option `--map-public-ip-on-launch` to Enable auto-assign public IPv4 address (for public subnets)

```sh
aws ec2 modify-subnet-attribute --subnet-id subnet-12345a432bb674be6 --map-public-ip-on-launch
```

Use the command `aws ec2 create-internet-gateway` to create **Internet Gateway**

```sh
aws ec2 create-internet-gateway --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=vpcIGW}]'
```

Use the below command to attach Internet Gateway to VPC

```sh
aws ec2 attach-internet-gateway --internet-gateway-id igw-030a40513e1a1c630 --vpc-id vpc-04123a432bb674be6
```

Use the command `aws ec2 allocate-address` to allocate an Elastic IP address

```sh
aws ec2 allocate-address --domain vpc
```

Use the command `aws ec2 create-nat-gateway` to create **NAT gateway**

```sh
aws ec2 create-nat-gateway \
  --subnet-id subnet-12345a432bb674be6 \
  --allocation-id eipalloc-0abcd1234efgh5678  \
  --tag-specifications 'ResourceType=natgateway,Tags=[{Key=Name,Value=myNATGateway},{Key=Environment,Value=PROD}]'
```


Use the command `aws ec2 create-route-table` to create **Route Table**

```sh
aws ec2 create-route-table --vpc-id vpc-04123a432bb674be6 --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=PrivateRouteTable}]'
```

Use the command `aws ec2 create-route` to add a route to route table. use option `--gateway-id` to add Internet Gateway and `--nat-gateway-id` to add NAT Gateway

```sh
aws ec2 create-route --route-table-id rtb-43257897321 --destination-cidr-block 0.0.0.0/0 --nat-gateway-id nat-12349876
aws ec2 create-route --route-table-id rtb-41234587123 --destination-cidr-block 0.0.0.0/0 --gateway-id igw-987449876
```


Use the command `associate-route-table` toassociate route table with subnet. Route table with internet Gateway is associated with public subnets and Route table with NAT Gateway is associated with private subnet 

```sh
aws ec2 associate-route-table --subnet-id subnet-12345a432bb674be6 --route-table-id rtb-41234587124
```

Use the command `ec2 create-security-group` to create **Security Group**

```sh
aws aws ec2 create-security-group --group-name testSecurityGroup --description "Test Security Group"  \
  --vpc-id vpc-04123a432bb674be6 --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=testSecurityGroup}]"'
```

Use the command `ec2 authorize-security-group-ingress` to add Inbound Rule to Security Group. Few examples are given below

```sh
# Allow HTTP (port 80) from another Security group
aws ec2 authorize-security-group-ingress \
    --group-id sg-abcdef1234567890 \
    --protocol tcp \
    --port 80 \
    --source-group sg-9876543210ab


# Allow HTTPS (port 443) from anywhere
aws ec2 authorize-security-group-ingress \
    --group-id sg-abcdef1234567890 \
    --protocol tcp \
    --port 443 \
    --cidr 0.0.0.0/0

# Allow HTTP (SSH) from anywhere
aws ec2 authorize-security-group-ingress \
    --group-id sg-abcdef1234567890 \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0
```

Use the command `ec2 authorize-security-group-egress` to add Inbound Rule to Security Group. Few examples are given below

```sh
# Allow HTTP (port 80) outbound to another Security group
aws ec2 authorize-security-group-egress \
    --group-id sg-abcdef1234567890 \
    --protocol tcp \
    --port 80 \
    --source-group sg-9876543210ab


# Allow HTTPS (port 443) outbound to anywhere
aws ec2 authorize-security-group-egress \
    --group-id sg-abcdef1234567890 \
    --protocol tcp \
    --port 443 \
    --cidr 0.0.0.0/0

# Allow HTTP (SSH) outbound to anywhere
aws ec2 authorize-security-group-egress \
    --group-id sg-abcdef1234567890 \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0
```