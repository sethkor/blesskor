key=bless
kmsalias=blesskorkms
subnets=subnet-0ef30901,subnet-0ef30901,subnet-8d437ac6,subnet-8d437ac6,subnet-8d437ac6,subnet-8d437ac6
public=true
user=seth
yourcidr=$(shell curl -s http://checkip.amazonaws.com/)/32
vpc=vpc-b8ccd7c0
zone=sethkor.com
PROFILE=sethkor-bless
STACK-NAME=blesskor
region=us-east-1
account=$(shell aws --profile $(PROFILE) sts get-caller-identity  --query 'Account' --output text)
ami=$(shell aws --profile $(PROFILE) ec2 describe-images --filters "Name=name,Values=Blesskor Bastion" --region $(region) --owner $(account)  --query 'sort_by(Images, &CreationDate) | [-1].ImageId' --output text)
iamprofile=arn:aws:iam::$(account):instance-profile/BlesskorBastionIamProfile
