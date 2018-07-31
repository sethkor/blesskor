#!/bin/bash -e

#
#    This script creates a Bastion IAM setup and associates to your KMS key
#


function usage
{
    echo 
"usage: create-bastion-iam.sh [-h]     --region APACHE_CONF
                                    --project_name PROJECT_NAME
"
}

project=""
region=


echo "Checking Args"
while [ "$1" != "" ]; do
    case $1 in
        -p | --project_name )   shift
                                project=$1
                                ;;
        -r | --region )         shift
                                region=$1
                                ;; 
        -h | --help )           usage
                                exit
                                ;;
    esac
    shift
done

if [ "$project" = "" ] || [ "$region" = "" ]
then
  usage
  exit
fi


create-role --role-name BastionLambdaIamRole --assume-role-policy-document file://iam-role-lambda.json
create-policy --policy-name BastionLambdaIamPolicy --path / --policy-document file://iam-policy-lambda.json
aws iam attach-role-policy --role-name BastionLambdaIamRole --policy-arn arn:aws:iam::293499315857:policy/BastionLambdaIamPolicy

aws iam create-instance-profile --instance-profile-name BlesskorBastionIamProfile
aws iam create-role --role-name BastionIamRole --assume-role-policy-document file://iam-role.json
aws iam create-policy --policy-name BastionIamPolicy --path / --policy-document file://iam-policy.json
aws iam attach-role-policy --role-name BastionIamRole --policy-arn arn:aws:iam::293499315857:policy/BastionIamPolicy
aws iam add-role-to-instance-profile --instance-profile-name BlesskorBastionIamProfile --role-name BastionIamRole

aws kms --region ap-southeast-2 create-grant --key-id arn:aws:kms:ap-southeast-2:293499315857:alias/sethkor --grantee-principal ${BastionInstanceProfile.Arn} --operations Encrypt


aws iam remove-role-from-instance-profile --instance-profile-name BlesskorBastionIamProfile --role-name BastionIamRole
aws iam detach-role-policy --role-name BastionIamRole --policy-arn arn:aws:iam::293499315857:policy/BastionIamPolicy
aws iam delete-role --role-name BastionIamRole
aws iam delete-policy --policy-arn arn:aws:iam::293499315857:policy/BastionIamPolicy
aws iam delete-instance-profile --instance-profile-name BlesskorBastionIamProfile
aws kms --region ap-southeast-2 create-grant --key-id arn:aws:kms:ap-southeast-2:293499315857:key/c2af3c33-c3ff-4fba-bbce-a6ed4ad0865b --grantee-principal arn:aws:iam::293499315857:role/BastionLambdaIamRole --operations Decrypt


aws iam detach-role-policy --role-name BastionLambdaIamRole --policy-arn arn:aws:iam::293499315857:policy/BastionLambdaIamPolicy
aws iam delete-role --role-name BastionLambdaIamRole
aws iam delete-policy --policy-arn arn:aws:iam::293499315857:policy/BastionLambdaIamPolicy


# #Create the VPC
# vpcid=$(aws ec2 create-vpc --region us-east-1 --cidr-block 10.0.0.0/16 | jq '.Vpc.VpcId' | tr -d '"')
# 
# #Store the vppc name into credstash
# credstash delete boinc.$project.vpc.$region
# credstash put boinc.$project.vpc.$region $vpcid
# 
# #Tag the VPC with a Name
# aws ec2 create-tags --region $region --resources $vpcid --tags Key=Name,Value="Boinc Spot Fleet"
# 
# #Add the extra CIDR blocks
# aws ec2 associate-vpc-cidr-block --region $region --cidr-block 10.1.0.0/16 --vpc-id $vpcid
# aws ec2 associate-vpc-cidr-block --region $region --cidr-block 10.2.0.0/16 --vpc-id $vpcid
# aws ec2 associate-vpc-cidr-block --region $region --cidr-block 10.3.0.0/16 --vpc-id $vpcid
# aws ec2 associate-vpc-cidr-block --region $region --cidr-block 10.4.0.0/16 --vpc-id $vpcid