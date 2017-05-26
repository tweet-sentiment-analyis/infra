#!/bin/bash
AWS_ACCESS_KEY_ID=""
AWS_SECRET_ACCESS_KEY=""
sshKeyName=""

echo
echo "Starting setup..."

if [ ${#AWS_ACCESS_KEY_ID} -eq 0 ] || [ ${#AWS_SECRET_ACCESS_KEY} -eq 0 ] || [ ${#sshKeyName} -eq 0 ]
then
	echo "Please fill in the 3 vars at the top of the file"
else

	echo "	Receiving elastic search url..."
	elasticSearchEndpoint=$(aws es describe-elasticsearch-domain --domain-name "tweetanalyzer" --query "DomainStatus.Endpoint")


	if [ ${#elasticSearchEndpoint} -gt 0 ]
	then
		echo "	Checking available subnets..."
		subnets=$(aws ec2 describe-subnets --query "Subnets[*].SubnetId")
		temp="${subnets%]}"
		subnets="${temp#[}"
		subnets=$(echo "$subnets" | sed "s/\"//g")

		echo "	Check available security groups..."
		securityGroup=$(aws ec2 describe-security-groups --query "SecurityGroups[?GroupName=='default'].IpPermissions[][UserIdGroupPairs][][][GroupId][]")
		temp="${securityGroup%]}"
		securityGroup="${temp#[}"

		echo
		echo "Setting up SQS"
		echo "	analyised-tweets"
		aws sqs create-queue --cli-input-json file://AnalyisedTweetsSQS.json
		echo "	fetched-tweets"
		aws sqs create-queue --cli-input-json file://FetchedTweetsSQS.json


		echo
		echo "	Setting up Analyzer..."

		echo "		Prepare Userdata..."
		dockerRunText=`cat dockerRunAnalyzer.txt`
		dockerRunText=${dockerRunText//ACCESSKEY/$AWS_ACCESS_KEY_ID}
		dockerRunText=${dockerRunText//SECRETKEY/$AWS_SECRET_ACCESS_KEY}

		userdata=$'#!/bin/bash\\n'
		userdata="$userdata$dockerRunText"

		echo "		Setting up LauchConfiguration JSON..."
		launchConfigText=`cat LaunchConfigurationsAnalyzer.json`
		launchConfigText=${launchConfigText//USERDATAVAR/$userdata}
		launchConfigText=${launchConfigText//SECURITYGROUPID/$securityGroup}
		launchConfigText=${launchConfigText//SSHKEYNAME/$sshKeyName}

		echo $launchConfigText > LaunchConfigurationsAnalyzer_prepared.json

		echo "		Setting up launch configuration..."
		aws autoscaling create-launch-configuration --cli-input-json file://LaunchConfigurationsAnalyzer_prepared.json
		echo "		Setting up auto scaling group..."
		aws autoscaling create-auto-scaling-group --cli-input-json file://AutoScalingGroupsAnalyzer.json
		echo "		Update auto scaling group..."
		aws autoscaling update-auto-scaling-group --auto-scaling-group-name ASE_ASG_Analyzer --vpc-zone-identifier "$subnets"
		aws autoscaling create-or-update-tags --tags "ResourceId=ASE_ASG_Analyzer,ResourceType=auto-scaling-group,Key=Type,Value=Analyzer,PropagateAtLaunch=true"
		echo "		Setting up auto scaling group metrics..."
		aws autoscaling enable-metrics-collection --cli-input-json file://AutoScalingGroupMetricsAnalyzer.json

		echo "		Setting up ScaleoutPolicy..."
		scaleOutARN=$(aws autoscaling put-scaling-policy --policy-name my-sqs-scaleout-policy --auto-scaling-group-name ASE_ASG_Analyzer --scaling-adjustment 1 --adjustment-type ChangeInCapacity --query "PolicyARN")
		echo "		Setting up ScaleinPolicy..."
		scaleInARN=$(aws autoscaling put-scaling-policy --policy-name my-sqs-scalein-policy --auto-scaling-group-name ASE_ASG_Analyzer --scaling-adjustment -1 --adjustment-type ChangeInCapacity --query "PolicyARN")

		echo "		Put alarm metric: scale in..."
		temp="${scaleInARN%\"}"
		scaleInARN="${temp#\"}"
		aws cloudwatch put-metric-alarm --alarm-name RemoveCapacityFromFetchedQueue --metric-name ApproximateNumberOfMessagesVisible --namespace "AWS/SQS" --statistic Average --period 60 --threshold 20 --comparison-operator LessThanOrEqualToThreshold --dimensions Name=QueueName,Value=fetched-tweets --evaluation-periods 1 --alarm-actions $scaleInARN

		echo "		Put alarm metric: scale out..."
		temp="${scaleOutARN%\"}"
		scaleOutARN="${temp#\"}"
		aws cloudwatch put-metric-alarm --alarm-name AddCapacityToFetchedQueue --metric-name ApproximateNumberOfMessagesVisible --namespace "AWS/SQS" --statistic Average --period 60 --threshold 30 --comparison-operator GreaterThanOrEqualToThreshold --dimensions Name=QueueName,Value=fetched-tweets --evaluation-periods 1 --alarm-actions $scaleOutARN

		echo "	Analyzer done"

		echo
		echo "	Setting up ES producer..."

		echo "		Prepare Userdata..."
		temp="${elasticSearchEndpoint%\"}"
		elasticSearchEndpoint="${temp#\"}"

		dockerRunText=`cat dockerRunESproducer.txt`
		dockerRunText=${dockerRunText//ACCESSKEY/$AWS_ACCESS_KEY_ID}
		dockerRunText=${dockerRunText//SECRETKEY/$AWS_SECRET_ACCESS_KEY}
		dockerRunText=${dockerRunText//AWSHOSTURL/$elasticSearchEndpoint}

		userdata=$'#!/bin/bash\\n'
		userdata="$userdata$dockerRunText"

		echo "		Setting up LauchConfiguration JSON..."
		launchConfigText=`cat LaunchConfigurationsESProducer.json`
		launchConfigText=${launchConfigText//USERDATAVAR/$userdata}
		launchConfigText=${launchConfigText//SECURITYGROUPID/$securityGroup}
		launchConfigText=${launchConfigText//SSHKEYNAME/$sshKeyName}

		echo $launchConfigText > LaunchConfigurationsESProducer_prepared.json

		echo "		Setting up launch configuration..."
		aws autoscaling create-launch-configuration --cli-input-json file://LaunchConfigurationsESProducer_prepared.json
		echo "		Setting up auto scaling group..."
		aws autoscaling create-auto-scaling-group --cli-input-json file://AutoScalingGroupsESProducer.json
		echo "		Update auto scaling group..."
		aws autoscaling update-auto-scaling-group --auto-scaling-group-name ASE_ASG_ESProducer --vpc-zone-identifier "$subnets"
		aws autoscaling create-or-update-tags --tags "ResourceId=ASE_ASG_ESProducer,ResourceType=auto-scaling-group,Key=Type,Value=ESProducer,PropagateAtLaunch=true"
		echo "		Setting up auto scaling group metrics..."
		aws autoscaling enable-metrics-collection --cli-input-json file://AutoScalingGroupMetricsESProducer.json

		echo "		Setting up ScaleoutPolicy..."
		scaleOutARN=$(aws autoscaling put-scaling-policy --policy-name my-es-sqs-scaleout-policy --auto-scaling-group-name ASE_ASG_ESProducer --scaling-adjustment 1 --adjustment-type ChangeInCapacity --query "PolicyARN")
		echo "		Setting up ScaleinPolicy..."
		scaleInARN=$(aws autoscaling put-scaling-policy --policy-name my-es-sqs-scalein-policy --auto-scaling-group-name ASE_ASG_ESProducer --scaling-adjustment -1 --adjustment-type ChangeInCapacity --query "PolicyARN")

		echo "		Put alarm metric: scale in..."
		temp="${scaleInARN%\"}"
		scaleInARN="${temp#\"}"
		aws cloudwatch put-metric-alarm --alarm-name RemoveCapacityFromProcessQueue --metric-name ApproximateNumberOfMessagesVisible --namespace "AWS/SQS" --statistic Average --period 60 --threshold 20 --comparison-operator LessThanOrEqualToThreshold --dimensions Name=QueueName,Value=analyised-tweets --evaluation-periods 1 --alarm-actions $scaleInARN

		echo "		Put alarm metric: scale out..."
		temp="${scaleOutARN%\"}"
		scaleOutARN="${temp#\"}"
		aws cloudwatch put-metric-alarm --alarm-name AddCapacityToProcessQueue --metric-name ApproximateNumberOfMessagesVisible --namespace "AWS/SQS" --statistic Average --period 60 --threshold 30 --comparison-operator GreaterThanOrEqualToThreshold --dimensions Name=QueueName,Value=analyised-tweets --evaluation-periods 1 --alarm-actions $scaleOutARN

		echo "	ES producer done"
		echo "Setup done!"
	else
		echo "Elastic search url not found. Aborting!"
	fi
fi