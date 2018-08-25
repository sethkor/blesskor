key=
kmsalias=blesskorkms
subnets=/*Put your comma seperated bastions subnets here like this subnet-0ef30901,subnet-3113631e,subnet-8d437ac6 */
public=true
user=sethkor
yourcidr=$(shell curl -s http://checkip.amazonaws.com/)/32
vpc=/*Put your VPC ID here*/
PROFILE=sethkor-bless
STACK-NAME=blesskor
region=us-east-1
account=$(shell aws --profile $(PROFILE) sts get-caller-identity  --query 'Account' --output text)
ami=$(shell aws --profile $(PROFILE) ec2 describe-images --filters "Name=name,Values=Blesskor Bastion" --region $(region) --owner $(account)  --query 'sort_by(Images, &CreationDate) | [-1].ImageId' --output text)
iamprofile=arn:aws:iam::$(account):instance-profile/BlesskorBastionIamProfile
