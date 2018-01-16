#!/bin/sh -xe

sudo yum update -y
sudo yum install -y git gcc libffi-devel openssl-devel docker
#sudo usermod -a -G docker ec2-user

git clone https://github.com/Netflix/bless.git

cd bless
 
virtualenv venv
 
source venv/bin/activate
 
make develop
 
make test

sudo service docker start

echo "Executing Make"

echo "--> Compiling lambda dependencies"
sudo docker run --rm -v $PWD:/src -w /src amazonlinux make compile

rm ~/.ssh/authorized_keys




