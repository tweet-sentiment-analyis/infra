Infrastructure Setup
====================

This repository holds configuration files in order to set up the cloud environment on AWS.

# How to setup

Please note, that the following setup steps have only been tested on Mac OS.
Additionally, be prepared, that our setup script uses the default security group and subnets to set up instances.

## Prerequisites
An IAM role with admin access is needed to run the setup scripts. 
Please create a role with these permissions and note the corresponding AWS access key and the secret key for that role.
Further a SSH connection private key-pair is required during the setup of the EC2 instances. 
Please create one, as described on the [AWS documentation](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html#having-ec2-create-your-key-pair)

In order to run the setup script, the ASW CLI is required. Please install it according to the [AWS documentation](http://docs.aws.amazon.com/cli/latest/userguide/installing.html).
Once ASW CLI is installed it has to be configured using the following command in the terminal: `aws configure`.
Please provide the AWS access key and secret key when promted. 
Please also choose `us-west-2` as the region, and leave the last prompt empty.

## Setting up the backend:
1.  Set up elastic search by running the script `Setup_ElasticSearch.sh`. Setting up elastic search can take up to 15 min. Note, that the setup can only continue once Elasticsearch has been correctly setup.
2.  Check the status of elastic search at [https://us-west-2.console.aws.amazon.com/es/home?region=us-west-2](https://us-west-2.console.aws.amazon.com/es/home?region=us-west-2#) or run the following command in the terminal: `aws es describe-elasticsearch-domain --domain-name "tweetanalyzer" --query "DomainStatus.Endpoint"`. If the resopnse is not `null` Elasticsearch is ready.
3. Open the `setup-ec2.sh` file with any text editor and fill in the three lines at the top with your credentials and the name of the ssh key:
```
    AWS_ACCESS_KEY_ID="FILLOUT"
    AWS_SECRET_ACCESS_KEY="FILLOUT"
    sshKeyName="FILLOUT"
```
4. Save the changes and close the file.
5. You might need to change the permission of both the `setup-ec2.sh` and the ssh `.pem` file in order to run the script:
```
    chmod +x /path/to/yourscript.sh
    chmod 400 /path/to/yourkey.pem
```
6. You can now run the `setup-ec2.sh` with: `./setup-ec2.sh`
7. If no errors are displayed the backend is setup and running

## Setting up the fetcher and the frontend:

## Setting up the Load Generator


# Clean up when finished:
1. Remove all instances and autoscaling groups with: `./CleanUp.sh`
2. Shut down elastic search with: `./ElasticSearchCleanUp.sh`
