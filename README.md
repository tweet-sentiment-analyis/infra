# How to setup:

The follwing setup steps have only been tested on Mac OS:

Note: Our setup script uses the default security group and subnets to set up instances!

Prerequisites:
A IAM role with admin access is needed to run the setup scripts. Please create a role and create an aws access key and the aws secret key for that role.
Further a ssh connection key is required during the setup. Please create one

In order to run the setup script ASW CLI is needed: http://docs.aws.amazon.com/cli/latest/userguide/installing.html
Once ASW CLI is installed it has to be configured using the following command in the terminal: aws configure
Please provide the aws access key and the aws secret key when promted. Please choose the us-west-2 as the region, and leave the last prompt empty

Setting up the backend:
1. 	Set up elastic search by running the Setup_ElasticSearch.sh
	Setting up elastic search can take up to 15 min. The setup can only continue once elastic search has been correctly setup.
2. 	Check the status of elastic search under: https://us-west-2.console.aws.amazon.com/es/home?region=us-west-2# or run the following command in the terminal: 
aws es describe-elasticsearch-domain --domain-name "tweetanalyzer" --query "DomainStatus.Endpoint"
if the resopnse is not 'null' elastic search is ready
3. Open the setup-ec2.sh file with any text editor and fill in the three lines at the top with your credentials and the name of the ssh key:

AWS_ACCESS_KEY_ID="FILLOUT"
AWS_SECRET_ACCESS_KEY="FILLOUT"
sshKeyName="FILLOUT"

4. Save the changes and close the file.
5. You might need to change the permission of both the setup-ec2.sh and the ssh .pem file in order to run the script:
chmod +x /path/to/yourscript.sh
chmod 400 /path/to/yourkey.pem

6. You can now run the setup-ec2.sh with: ./setup-ec2.sh
7. If no errors are displayed the backend is setup and running

Setting up the fetcher and the frontend:




Clean up when finished:
1. Remove all instances and autoscaling groups with: ./CleanUp.sh
2. Shut down elastic search with: ./ElasticSearchCleanUp.sh
