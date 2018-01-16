#!/bin/bash

sudo yum -y install git gcc 
sudo yum -y install libffi-devel openssl-devel docker
git clone https://github.com/Netflix/bless.git
cd bless
virtualenv venv
source venv/bin/activate
make develop
make test
sudo service docker start
sudo make lambda-deps
ssh-keygen -t rsa -b 4096 -f bless-ca -C "SSH CA Key"
aws kms encrypt --region ap-southeast-2 --key-id alias/sethkor --plaintext IPityTheFool --output text --query CiphertextBlob > YourKmsEncryptedPasswordFool.kms
cp bless/config/bless_deploy_example.cfg bless/config/bless_deploy.cfg

