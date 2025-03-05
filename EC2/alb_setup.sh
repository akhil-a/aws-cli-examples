#!/bin/bash
##FOR ALB
##TARGET GROUP CREATION



echo "####################################################################################################"
echo "ALB Setup Script Started"
echo -e "####################################################################################################\n"

source infra.var
echo "Creating Target Group"

tg_name="targetGroup1"
tg_out=$(aws elbv2 create-target-group \
    --name ${tg_name} \
    --protocol HTTP \
    --port 80 \
    --vpc-id vpc-017a559a93d3a0dc1 \
    --target-type instance \
    --health-check-path "/health.html" \
    --health-check-protocol HTTP)
check_command_success
tg_arn=$(echo $tg_out | jq -r '.TargetGroups[0].TargetGroupArn')
check_empty ${tg_arn}
echo "Created Target Group ${tg_name}  : ${tg_arn}"

echo "Adding EC2 to target group"
 aws elbv2 register-targets \
    --target-group-arn ${tg_arn} \
    --targets Id=${app_server1_ID} Id=${app_server2_ID}


echo "Create Application Load Balancer"
alb_name="appALB"
alb_out=$(aws elbv2 create-load-balancer \
    --name ${alb_name} \
    --type application \
    --scheme internet-facing \
    --security-groups ${albSG_ID} \
    --subnets ${publicSubnet1_ID} ${publicSubnet2_ID} \
    --tags Key=Name,Value=appALB Key=Environment,Value=PROD)

check_command_success
alb_arn=$(echo $alb_out | jq -r '.LoadBalancers[0].LoadBalancerArn')
check_empty ${alb_arn}
echo "Created Application Load Balancer ${alb_name}  : ${alb_arn}"

echo "Create Listner for HTTP and add it to ${alb_name}"
listner_out=$(aws elbv2 create-listener \
    --load-balancer-arn ${alb_arn} \
    --protocol HTTP \
    --port 80 \
    --default-actions Type=forward,TargetGroupArn=${tg_arn})

listener_arn=$(echo $listner_out | jq -r '.Listeners[0].ListenerArn')
check_empty ${listener_arn}
echo "Created Listner ${listener_arn}  for ${alb_name}"

echo "alb_name=${alb_name}" >> infra.var
echo "alb_arn=${alb_arn}" >> infra.var
echo "tg_name=${tg_name}" >> infra.var
echo "tg_arn=${tg_arn}" >> infra.var
echo "listener_arn=${listener_arn}" >> infra.var


echo "####################################################################################################"
echo "ALB Script Completed Successfully :)"
echo -e "####################################################################################################\n"
cat infra.var
