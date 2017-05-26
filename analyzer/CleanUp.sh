#!/bin/bash
echo "Removing autoscale group of analyzer..."
aws autoscaling update-auto-scaling-group --auto-scaling-group-name "ASE_ASG_Analyzer" --min-size 0 --desired-capacity 0
aws autoscaling delete-auto-scaling-group --auto-scaling-group-name "ASE_ASG_Analyzer" --force-delete
echo "Removing autoscale group of ES producer..."
aws autoscaling update-auto-scaling-group --auto-scaling-group-name "ASE_ASG_ESProducer" --min-size 0 --desired-capacity 0
aws autoscaling delete-auto-scaling-group --auto-scaling-group-name "ASE_ASG_ESProducer" --force-delete
echo "Removing launch configuration of analyzer..."
aws autoscaling delete-launch-configuration --launch-configuration-name "ASE_LC_Analyzer"
echo "Removing launch configuration of ES producer..."
aws autoscaling delete-launch-configuration --launch-configuration-name "ASE_LC_ESProducer"
echo "Removing SQS queue: analyised-tweets"
queueUrl=$(aws sqs get-queue-url --queue-name "analyised-tweets" --query "QueueUrl")
temp="${queueUrl%\"}"
queueUrl="${temp#\"}"
aws sqs delete-queue --queue-url $queueUrl
echo "Removing SQS queue: fetched-tweets"
queueUrl=$(aws sqs get-queue-url --queue-name "fetched-tweets" --query "QueueUrl")
temp="${queueUrl%\"}"
queueUrl="${temp#\"}"
aws sqs delete-queue --queue-url $queueUrl