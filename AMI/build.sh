#!/bin/bash

#
#  Script to execute packer and store the ami id into credstash
#
#export PACKER_LOG=1
packer build -machine-readable packer.json | tee build.log
credstash delete boinc.server.ami.base
credstash put boinc.server.ami.base `grep 'artifact,0,id' build.log | cut -d, -f6 | cut -d: -f2`
rm build.log

