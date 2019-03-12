#! /bin/bash

static_instance_name_1="terraform-ec2"
autoscaling_group_name_1="test-exc-1"
recipients="ankurs@intertrust.com,ksingh@intertrust.com"
#set -x

#autoscaling_group_name_1_instance_info=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name ${autoscaling_group_name_1} --query "AutoScalingGroups[].Instances[].InstanceId")
#autoscaling_group_name_1_instance_info1=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name ${autoscaling_group_name_1} --query "AutoScalingGroups[].Instances[].InstanceId" |tr -d "[" | tr -d "]" | tr -d "\"")





static_ec2_name_1_instance_info=$(aws ec2 describe-instances --filters 'Name=tag:Name,Values=terraform-ec2' --query 'Reservations[*].Instances[].InstanceId'| tr -d '[' | tr -d ']' | tr -d '\"'| tr -d ' '| tr -d '\')
static_ec2_name_1_instance_count=${#static_ec2_name_1_instance_info[@]}
#if [[ ${static_ec2_name_1_instance_count} < 1 ]]; then
if [[ $(aws ec2 describe-instances --instance-ids $static_ec2_name_1_instance_info --query 'Reservations[].Instances[].State[].Name' --output text) == "stopped" ]]; then
	if [[ $(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name test-exc-1 --query 'AutoScalingGroups[].[DesiredCapacity]') == 0  ]]; then
		echo "Since static server is down, So adding instance to ${autoscaling_group_name_1}"
        	aws autoscaling update-auto-scaling-group --auto-scaling-group-name ${autoscaling_group_name_1} --min-size 1 --max-size 1 --desired-capacity 1
		sleep 180
		autoscaling_group_name_1_instance_info1=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name ${autoscaling_group_name_1} --query "AutoScalingGroups[].Instances[].InstanceId" |tr -d "[" | tr -d "]" | tr -d "\"")
        	echo  "$(aws ec2 describe-instances --instance-ids $autoscaling_group_name_1_instance_info1 --output table --region us-east-1 --query 'Reservations[].Instances[].{AZ:Placement.AvailabilityZone,State:State.Name,InstanceID:InstanceId,InstanceType:InstanceType,LaunchTime:LaunchTime,InstanceLifecycle:InstanceLifecycle,TAGS:Tags[?Key==`Name`] | [0].Value}')" | mail -s "Notification:increasing $autoscaling_group_name_1 autoscaling desired instance count to 1" $recipients
	else
	        echo "Although static server is down but already ASG is set to 1,so no any changes done"
	fi
else
        echo " Already 1 static instance is running !!!, reducing autoscaling group instance count to 0 if more than 1 running"
        aws autoscaling update-auto-scaling-group --auto-scaling-group-name ${autoscaling_group_name_1} --min-size 0 --max-size 0 --desired-capacity 0

fi
