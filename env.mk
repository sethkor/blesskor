ami=$(shell aws ec2 describe-images --filters "Name=name,Values=Blesskor Bastion" --region ap-southeast-2 --owner 293499315857  --query 'sort_by(Images, &CreationDate) | [-1].ImageId' --output text)
#$(shell aws ec2 describe-images --filters "Name=name,Values=amzn-ami-hvm-????.??.?.x86_64-gp2" --region ap-southeast-2 --owners amazon --query 'sort_by(Images, &CreationDate) | [-1].ImageId' --output text)
key=sethsyd1018
kmsalias=sethkor
subnets=subnet-594dee10,subnet-2bd4644c,subnet-f65855af
public=true
user=seth
yourcidr=115.69.50.209/32
#yourcidr=49.255.206.98/32
vpc=vpc-bfd836d8
zone=sethkor.com
PROFILE=default
STACK-NAME=blesskor
region=ap-southeast-2
iamprofile=arn:aws:iam::293499315857:instance-profile/BlesskorBastionIamProfile