#!/bin/bash

#######################################
# Captn - deploy script
#######################################
# Name: setv-api.dev
# Description: Synergie&vous API offre
# Date: 2016-12-28 04:46:32
# Local host: Thierry-PC
# SSH user: root
# SSH server: 213.56.106.169:22
# GIT user: 07516
# GIT repository: d:/depotsGit/setv-api.git
# Target dir: /var/www/html/setv-recruteur/
#######################################


# Variables

script_sh="C:\Users\Thierry\git\captn\server\script\setv-api.dev.sh"
script_name="setv-api.dev"
script_json="C:\Users\Thierry\git\captn\server\script\setv-api.dev.json"
script_temp="C:\Users\Thierry\git\captn\server\script\setv-api.dev"
script_date="2016-12-28 04:46:32"
script_local="Thierry-PC"
script_warning="coucou"
script_description="Synergie&vous API offre"
script_delay="0"
ssh_user="root"
ssh_host="213.56.106.169"
ssh_port="22"
git_branch="develop"
git_branch_remote=""
git_user="07516"
git_host="srv006.domsyn.fr"
git_dir="/var/www/html/setv-recruteur/"
git_repo="d:/depotsGit/setv-api.git"



# Functions


# Function to show informations on startup
function captn_start() {
	echo "captn_start: script \"$script_name\""
	echo "captn_start: $script_description"
	if [ "$script_warning" != "" ]; then
		echo "Warning: $script_warning"
	fi
	if [ "$script_delay" != "0" ] && [ "$script_delay" != "" ]; then
		count=`expr $script_delay + 0`
		while [ "$count" != "0" ]
		do
			if [ "$count" == "1" ]; then
				echo "Continue in $count second"
			else 
				echo "Continue in $count seconds"
			fi
			count=`expr $count - 1`
  			sleep 1
		done
	fi
}


# Function to clean temporary directory and files
function captn_clean() {
	echo "captn_clean: Start cleaning directory"
	echo "captn_clean: script temp directory is \"$script_temp\""
	echo "captn_clean: deleting directory"
	rm -fr "$script_temp"
	# Check delete error
	if [ $? != 0 ]; then
		(>&2 echo "captn_clean: failed to delete directory. Aborting.")
		exit 1;
	fi
	echo "captn_clean: recreating directory"
	mkdir "$script_temp"
	# Check creation error
	if [ $? != 0 ]; then
		(>&2 echo "captn_clean: failed to create directory. Aborting.")
		exit 1;
	fi
	echo "Success: script temp directory cleaned"
}


# Function to check ssh and git validity
function captn_check() {
	echo "captn_check: getting branch from server"
	echo "captn_check: connecting to $ssh_host:$ssh_port"
	{
		echo "$ssh_password" | ssh -tt -p $ssh_port $ssh_user@$ssh_host "cd /var/www/html/setv-recruteur/ && git rev-parse --abbrev-ref HEAD && git rev-parse HEAD"
	} > $script_temp/remote.txt 2> /dev/null
	return_code=$?
	if [ $(grep -c "fatal" $script_temp/remote.txt) -ne 0 ]; then
		(>&2 cat $script_temp/remote_branch.txt)
		(>&2 echo "captn_check: failed to get the remote branch name. Aborting.")
		exit 1;
	fi
	if [ $return_code -ne 0 ]; then
		(>&2 echo "captn_check: failed to connect to SSH. Aborting.")
		exit 1;
	fi
	git_branch_remote=`sed -n '2p' $script_temp/remote.txt`
	git_branch_remote="$(echo -e "${git_branch_remote}" | tr -d '[:space:]')"
	git_commit=`sed -n '3p' $script_temp/remote.txt`
	git_commit="$(echo -e "${git_commit}" | tr -d '[:space:]')"
#echo "git_branch_remote = $git_branch_remote"
#echo "git_branch = $git_branch"
#echo "git_commit = $git_commit"
	len=$(echo ${#git_commit})
#echo "len = $len"
	if [ "$git_commit" == "" ] || [ $len -ne 40 ]; then
		(>&2 echo "captn_check: invalid commit id \"$git_commit\"")
		exit 1;
	fi
	if [ "$git_branch_remote" != "$git_branch" ]; then
		(>&2 echo "captn_check: server branch \"$git_branch_remote\" in \"$git_dir\" is supposed to be \"$git_branch\".")
		exit 1;
	fi
	echo "Success: actual server branch is \"$git_branch_remote\""
	echo "Success: last commit is \"$git_commit\""
}


function captn_clone() {
	echo "captn_clone: cloning depository"
	cd "$script_temp"
	if [ $? != 0 ]; then
	    (>&2 echo "Could not change dir to \"$script_temp\". Aborting.")
	    exit 1;
	fi
	git clone $git_user@$git_host:$git_repo clone
	if [ $? != 0 ]; then
	    (>&2 echo "Could not clone project \"$git_repo\". Aborting.")
	    exit 1;
	fi
	cd "$script_temp/clone"
	if [ $? != 0 ]; then
	    (>&2 echo "Could not change dir to \"$script_temp/clone/\". Aborting.")
	    exit 1;
	fi
	echo "Success: repository cloned"
	git branch $git_branch
	if [ $? != 0 ]; then
	    (>&2 echo "Could not change to branch \"$git_branch\". Aborting.")
	    exit 1;
	fi


}

#######################################
# Command 1
captn_start
if [ $? != 0 ]; then
    (>&2 echo "Command failed. Aborting.")
    exit 1;
fi

#######################################
# Command 2
captn_clean
if [ $? != 0 ]; then
    (>&2 echo "Command failed. Aborting.")
    exit 1;
fi

#######################################
# Command 3
# captn_check
# Skip this command 

#######################################
# Command 4
captn_clone
if [ $? != 0 ]; then
    (>&2 echo "Command failed. Aborting.")
    exit 1;
fi

