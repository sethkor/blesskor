# Blesskor
Sethkor's AWS automation of NetFlix [BLESS](https://github.com/Netflix/bless).
I like BLESS, but it can be a real pain in the arse to get working for the first time, yeah.  So I've tried to automate it a little.

## Prerequisites
You'll need an [AWS](https://aws.amazon.com/) account if you dont already have one.
On your development machine you'll need to install [Make](https://www.gnu.org/software/make/) if you don't already have it installed, [Packer](https://www.packer.io/) to build an AMI, [Credstash](https://github.com/fugue/Credstash) to store your secrets, and a BLESS client which comes with the [BLESS](https://github.com/Netflix/bless) repo.  Make sure you have initilised Credstash in the AWS region you wish to deploy your BLESS bastion too.

Theres some Go alternatives to the above tools.  [Unicreds](https://github.com/Versent/unicreds) is a go client for Credstash, and you can also find a go BLESS client [here](https://github.com/Versent/bless).

Also you'll need to create yourself a KMS key for BLESS to use.  I haven't automated this as keys cost $ and it's a pain to script with checks to see if it already exists (read I'm lazy on this bit).  Make sure you create the KMS key in the region you wish to use the BLESS bastion via the AWS IAM console.  Also remember to create it with an alias.  For hygiene, its alwas good to enable automatic yearly rotation of your KMS keys.

Some commands below need your AWS config and screts they look something like this ```<YOUR-AWS-PROFILE>```.  Replace these bits with your info.


## Bake your bastion AMI
In the AMI directory are all the bits you need to bake your AMI.  I'm using Amazon Linux 2 Minimal for my bastion.  The minimal version is great because it doesn't from a security perspective as it doesn't have all that other guff that usually comes preinstalled on Amazon linux.

Make sure your AWS_PROFILE is set and then type:

```
make
```

or if you prefer

```
packer build packer.json 
```

## Set up all the IAM permissions needed
You'll need to create a few roles and policies.  This can't be done for BLESS in the same CloudFormation as the BLESS client and needs some sequencing.  for simplicty sake Ive done this in a shell script but you could try doing it in Ansible, Teraform or what ever tickles your fancy.  In the main dir just run

```
./bastion-iam.sh -k <YOUR-KMS-KEY-ID> -p <YOUR-AWS_PROFILE> -r <YOUR_AWS_REGION>
```
The KMS key is not the ARN, it's the long key id.

If you ever want to remove all these IAM bits you can use the same script

```
bastion-iam.sh delete
```

## Create your bastion
This automation creates a bastion in a public subnet and assigns an EIP to it.  AN EIP is used to ensure if the bastion terminates, another bastion replaces it using the same public IP address.

You'll need to update the env.mk files with a couple of things for this to work:

* VPC id (e.g. vpc-1234abcd) for the bastion
* Subnets (e.g. subnet-1234abcd,subnet-5678ijkl,subnet-9012efgh) within the VPC that the bastion can be instantiated
* PROFILE, the AWS profile to use to run the cfn stack
* Region, the AWS region to run the cfn stack and launch your bastion.  This should be the same region you baked your AMI in
* Kmskey, your KMS key id

You can also optionally set the STACK-NAME and user to something else if you like.

The automation uses autoscaling so can create a bastion in any of the subnets.  Only one bastion will ever exisit at a time.  In this example we create bastions in the public subnet so make sure you use public subnet ids.


As ssh keys are used in BLESS, when creating the bastion you'll need to pass a password for it to work.  In the main directory type:

```
make password=<YOUR-PASSWORD-HERE>
```

This will execute the cfn stack.
When the bastion is instatntiated it will do all the BLESS jiggery pokerry including deploying the BLESS lambda you'll need to get the certificate to log into your bastion.

The bastion takes a couple of minutes to be ready as it's building the lambda and generating a fresh set of keys.  The last step in the bastion creation is attaching the bastion to the EIP.  Once this is done you can start using the bastion.

### Conencting to the bastion
You'll need to install the [BLESS](https://github.com/Netflix/bless) client which is within the BESS repo or the [Go Client](https://github.com/Versent/bless).

In these examples Ill be using Credstash and the BLESS repo client.

When you in the client directory, you'll first need to get the keys your bastion has generated:

```
credstash --profile <YOUR-AWS-PROFILE> get bless-ca.pem > bless-ca.pem
credstash --profile <YOUR-AWS-PROFILE> get bless-ca.pub > bless-ca.pub
```
Set the proper permissions and add the key to your ssh agent

```
chmod 400 bless-ca.pem
ssh-add -K bless-ca.pem
```

You may be prompted for the password for the key which is the same password you passed to the make command.

Then run the BLESS client which will call the lambda to get your signed public certificate to log into the bastion.  The bless client requires you to have your AWS_PROFILE environment var set in order fo rit to work too:

```
export AWS_PROFILE=<YOUR-AWS-PROFILE>
./bless_client.py <YOUR-AWS-REGION> blesskor-bastion <YOUR-LOCAL-USER> <YOUR-BASTION-IP-ADDRESS> ec2-user <YOUR-IP-ADDRESS> ssh bless-ca.pub result.pub
```

If this works you should see:
```
Wrote Certificate to: result.pub
```

Then you have your certificate to use.  Remember as it's BLESS, it has a short lifetime.  I've set it to two minutes so you need to use the certificate straight away.  Type:

```
ssh - result.pub ecs-user@<YOUR-BASTION-IP-ADDRESS>
```

You should be connected to your bastion now!

## Troubleshooting

### Validating certificates


```
ssh-keygen -L -f /etc/ssh/cas.pub #or path to cert
```

### Debugging the bastion host
If you are having trouble connecting to the bastion with the public certific, you can add a SSH key pair to the host so that you can ssh into it the normal way and debug sshd from there.  But beware when doing this as you are effectivly bypassing the whole point of BLESS by not having ssh key pairs.  To add a key set the key paramater in env.mk.  Then edit the cloud formation yaml file ```bless-cfn.yaml``` and uncomment the line `KeyName` from the launch configuration.  You can update the CFN with this stack via ```make cfn-update password=<YOUR-PASSWORD-HERE>``` or delete the stack and recreate from scratch.  If you choose to just update the stack terminate the existing bastion once the stack update is complete so that a new bastion is created with the auto scaling group with the key pair you have specified.  Once you have finished your debugging, remove the keypair from the env.mk and follow the update stack steps again in order to recreate a bastion without a key pair and test BLESS properly.

### Debugging Certificate Validation
On bastion host, edit the /etc/sysconfig/sshd file  add the following line to anywhere in the file

```
OPTIONS="-ddd"
```

Save and quit, Then restart the service sudo service sshd restart command.  Tail the ```/var/log/messages``` file.  you'll need to be a privedledged user (root) to do that.


### Too many authentication failures
Your ssh agent has too many stored keys.  You need to flush it.  To see the keys stored type:

```
ssh-add -l
```

Flush it and read just your key by typing:

```
ssh-add -D
ssh-add -K bless-ca.pem
```

### The security token included in the request is invalid
If you get this when invoking bless_client.py it's ususally because bless_client.py is picking the wrong AWS\_PROFILE to use and is not executing the lambda in the correct account.  Try setting AWS\_PROFILE environment vairable to your AWS\_PROFILE.  You can also copy paste the payload json into a test event in the AWS lambda console and test it there.

