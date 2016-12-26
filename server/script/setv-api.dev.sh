#!/bin/bash

#######################################
# Captn - deploy script
#######################################
# Date: 2016-12-26 02:46:20
# Host: Thierry-PC
# SSH user:  (Thierry)
# To server: 213.56.106.163
#######################################


#######################################
# Command 1
ls -l
if [ $? != 0 ]; then
    (>&2 echo "Command failed. Aborting.")
    exit 1;
fi

#######################################
# Command 2
# skip
# Skip this command 

#######################################
# Command 3
ls -l
if [ $? != 0 ]; then
    (>&2 echo "Command failed. Aborting.")
    exit 1;
fi
echo  "ok"

#######################################
# Command 4
ls -l azerty
if [ $? != 0 ]; then
    (>&2 echo  "error")
    exit 1;
fi

