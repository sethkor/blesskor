#!/bin/sh -xe

# Install with Yum all our dependecies and make sure our AMI is all up to date
sudo yum update -y
sudo yum install -y git gcc libffi-devel openssl-devel docker fail2ban
sudo chkconfig fail2ban on

# We also need Credstash for Secrets Management
sudo pip install credstash

# Clone the repo
git clone https://github.com/Netflix/bless.git

#Build Bless
cd bless
virtualenv venv 
source venv/bin/activate
make develop
make test
sudo service docker start
sudo docker run --rm -v $PWD:/src -w /src amazonlinux make compile

#Get rid of the default packer SSH keys
rm ~/.ssh/authorized_keys




