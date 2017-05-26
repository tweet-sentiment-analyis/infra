#!/bin/bash
echo
echo "Setting up elastic search on amazon..."
echo "	Retrieving aws account id"
aws_account_id=$(aws ec2 describe-security-groups --group-names 'Default' --query 'SecurityGroups[0].OwnerId' --output text)

echo "	Preparing json for ES creation..."
jsonText=`cat ElasticSearch.json`
jsonText=${jsonText//AWSACCOUNTID/$aws_account_id}
echo $jsonText > ElasticSearch_prepared.json
aws es create-elasticsearch-domain --domain-name "tweetanalyzer" --cli-input-json file://ElasticSearch_prepared.json
echo "Done"
