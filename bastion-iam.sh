#!/bin/bash

#
#    This script creates a Bastion IAM setup and associates to your KMS key for use
#	   by BLESS
#


function usage
{
    echo  "usage: bastion-iam.sh           --key KMS_KEY_ID
                                --profile AWS_PROFILE
                                --region AWS_REGION 
                                [-d --delete]
                                [-h --help]
"
}

profile=""
region=""
delete="false";
key=""


while [ "$1" != "" ]; do
    case $1 in
        -k | --key )   					shift
                                key=$1
                                ;;
        -p | --profile )   			shift
                                profile=$1
                                ;;
        -r | --region )         shift
                                region=$1
                                ;; 
        -d | --delete )         delete="true"
                                ;;                                
        -h | --help )           usage
                                exit
                                ;;
    esac
    shift
done

if [ "$profile" = "" ] || [ "$region" = "" ] || [ "$delete" = "false" ] && [ "$key" = "" ]
then
  usage
  exit
fi

account=$(aws --profile $profile sts get-caller-identity  --query 'Account' --output text)

if [ "$delete" = "false" ]
then
	set -x
 	aws --profile $profile iam create-role --role-name BastionLambdaIamRole --assume-role-policy-document file://iam-role-lambda.json
 	aws --profile $profile iam create-role --role-name BastionIamRole --assume-role-policy-document file://iam-role-ec2.json
  aws --profile $profile iam create-policy --policy-name BastionLambdaIamPolicy --path / --policy-document "`sed \"s|account|"$account"|g\" iam-policy-lambda.json | sed \"s|region|"$region"|g\"`"
 	aws --profile $profile iam attach-role-policy --role-name BastionLambdaIamRole --policy-arn arn:aws:iam::$account:policy/BastionLambdaIamPolicy
 	aws --profile $profile iam create-instance-profile --instance-profile-name BlesskorBastionIamProfile
 	aws --profile $profile iam create-policy --policy-name BastionIamPolicy --path / --policy-document "`sed \"s|account|"$account"|g\" iam-policy-ec2.json | sed \"s|region|"$region"|g\" | sed \"s|key|key/"$key"|g\"`"
	aws --profile $profile iam attach-role-policy --role-name BastionIamRole --policy-arn arn:aws:iam::$account:policy/BastionIamPolicy
	aws --profile $profile iam add-role-to-instance-profile --instance-profile-name BlesskorBastionIamProfile --role-name BastionIamRole
	#The above add-role-to-instance-profile command takes a few seconds to take hold so we have a little sleep here
	sleep 5
	aws --profile $profile kms --region $region create-grant --key-id arn:aws:kms:$region:$account:key/$key --grantee-principal arn:aws:iam::$account:role/BastionLambdaIamRole --operations Decrypt
	aws --profile $profile kms --region $region create-grant --key-id arn:aws:kms:$region:$account:key/$key --grantee-principal arn:aws:iam::$account:role/BastionIamRole --operations Encrypt
	set +x

else
	set -x
	aws --profile $profile iam detach-role-policy --role-name BastionLambdaIamRole --policy-arn arn:aws:iam::$account:policy/BastionLambdaIamPolicy
	aws --profile $profile iam delete-role --role-name BastionLambdaIamRole
	aws --profile $profile iam delete-policy --policy-arn arn:aws:iam::$account:policy/BastionLambdaIamPolicy	
	aws --profile $profile iam remove-role-from-instance-profile --instance-profile-name BlesskorBastionIamProfile --role-name BastionIamRole
	aws --profile $profile iam detach-role-policy --role-name BastionIamRole --policy-arn arn:aws:iam::$account:policy/BastionIamPolicy
	aws --profile $profile iam delete-role --role-name BastionIamRole
	aws --profile $profile iam delete-policy --policy-arn arn:aws:iam::$account:policy/BastionIamPolicy
	aws --profile $profile iam delete-instance-profile --instance-profile-name BlesskorBastionIamProfile
	set +x
fi

