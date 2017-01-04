#!/bin/bash

#######################################
# Captn - deploy script
#######################################
# Name: test
# Description: Synergie&vous API offre
# Date: 2017-01-04 17:33:12
# Local host: SYN1506
# SSH user: root
# SSH server: 213.56.106.169:22
# GIT user: 07516
# GIT repository: d:/depotsGit/setv-api.git
# Target dir: /var/www/html/setv-api/
#######################################


# Variables

script_description="Synergie&vous API offre"
script_warning=""
script_delay="0"
ssh_host="213.56.106.169"
ssh_port="22"
ssh_user="root"
git_host="srv006.domsyn.fr"
git_repo="d:/depotsGit/setv-api.git"
git_user="07516"
git_branch="develop"
git_dir="/var/www/html/setv-api/"
git_commit=""
git_commit_limit="10"
git_commit_default=""
remote_dir="/var/www/html/setv-api/"
bin_shell="bash"
bin_php="php"
bin_phing="phing"
script_name="test"
script_file="script/test.json"
script_json="C:\Users\PR033\git\captn\server\script\test.json"
script_dir="C:\Users\PR033\git\captn\server\script\test"
script_sh="C:\Users\PR033\git\captn\server\script\test.sh"
script_action="default"
script_date="2017-01-04 17:33:12"
script_local="SYN1506"
script_true_values="y Y yes Yes YES 1 true ok yep"
git_commit_list=""
git_commit_head=""


# File C:\Users\PR033\git\captn\server/lib/functions.captn.sh





#################################################
#################################################
# Functions


#################################################
# Start with some informations about the script

# Function to show informations on startup
function captn_infos() {
	echo "captn_start: script \"$script_name\""
	echo "captn_start: $script_description"
	if [ "$script_warning" != "" ]; then
		echo "Warning: $script_warning"
	fi
	if [ "$script_delay" != "0" ] && [ "$script_delay" != "" ]; then
		echo "Continue in $script_delay seconds"
  		sleep $script_delay
	fi
}


#################################################
# Clean

# Function to clean local cache files
function captn_clean() {
	local function_name="captn_clean"
	echo "$function_name: Start cleaning"
	echo "$function_name: script cache directory is \"$script_dir\""
	echo "$function_name: deleting all files in directory"
	rm -fr "$script_dir/*.*"
	# Check delete error
	if [ $? != 0 ]; then
		(>&2 echo "$function_name: failed to delete directory. Aborting")
		exit 1;
	fi
	if [ ! -d $script_dir ]; then
		mkdir "$script_dir"
		# Check creation error
		if [ $? != 0 ]; then
			(>&2 echo "$function_name: failed to create directory. Aborting")
			exit 1;
		fi
	fi
	echo "Success: script cache files cleaned"
}

# Function to delete and recreate local cache directory
function captn_clean_all() {
	local function_name="captn_clean_all"
	echo "$function_name: Start cleaning"
	echo "$function_name: script cache directory is \"$script_dir\""
	echo "$function_name: deleting directory"
	rm -fr "$script_dir"
	# Check delete error
	if [ $? != 0 ]; then
		(>&2 echo "$function_name: failed to delete directory. Aborting")
		exit 1;
	fi
	echo "$function_name: recreating directory"
	mkdir "$script_dir"
	# Check creation error
	if [ $? != 0 ]; then
		(>&2 echo "$function_name: failed to create directory. Aborting")
		exit 1;
	fi
	echo "Success: script cache directory cleaned"
}

# Function to delete the cloned repository
function captn_clean_clone() {
	local function_name="captn_clean_clone"
	echo "$function_name: Start cleaning cloned directory"
	echo "$function_name: script cache directory is \"$script_dir\""
	echo "$function_name: deleting cloned directory"
	rm -fr "$script_dir/clone/"
	# Check delete error
	if [ $? != 0 ]; then
		(>&2 echo "$function_name: failed to delete directory. Aborting")
		exit 1;
	fi
	echo "Success: script clone directory deleted"
}


#################################################
# Check git remote

# Function to check remote server by SSH
function captn_check_git_remote() {
	local function_name="captn_check_git_remote"
	echo "$function_name: getting branch from remote server"
	echo "$function_name: connecting to $ssh_host:$ssh_port"
	{
		ssh -tt -p $ssh_port $ssh_user@$ssh_host "cd $git_dir && git rev-parse --abbrev-ref HEAD && git rev-parse HEAD"
	} > $script_dir/remote.txt 2> /dev/null
	return_code=$?
	if [ $(grep -c "fatal" $script_dir/remote.txt) -ne 0 ]; then
		(>&2 cat $script_dir/remote_branch.txt)
		(>&2 echo "$function_name: failed to get the remote branch name. Aborting")
		exit 1;
	fi
	if [ $return_code -ne 0 ]; then
		(>&2 echo "$function_name: failed to connect to SSH. Aborting.")
		exit 1;
	fi

	line=1
	first_line=`sed -n ${line}p $script_dir/remote.txt`
	if [ "$first_line" == "" ]; then
		line=2
		first_line=`sed -n ${line}p $script_dir/remote.txt`
	fi
	git_branch_remote="$first_line" # `sed -n ${line}p $script_dir/remote.txt`
	line="$(($line+1))"
	git_commit_remote=`sed -n ${line}p $script_dir/remote.txt`
	len=$(echo ${#git_commit_remote})
	if [ "$git_commit_remote" == "" ] || [ $len -ne 40 ]; then
		(>&2 echo "$function_name: invalid commit id \"$git_commit_remote\"")
		exit 1;
	fi
	if [ "$git_branch_remote" != "$git_branch" ]; then
		(>&2 echo "$function_name: server branch \"$git_branch_remote\" in \"$git_dir\" is supposed to be \"$git_branch\".")
		exit 1;
	fi
	echo "Success: remote server branch is \"$git_branch_remote\""
	echo "Success: remote server last commit is \"$git_commit_remote\""
}


#################################################
# Clone

function captn_clone_local() {
	local function_name="captn_clone_local"

	############################################
	# cloning
	echo "$function_name: start"
	cd "$script_dir"
	if [ $? != 0 ]; then
	    (>&2 echo "Could not change dir to \"$script_dir\". Aborting")
	    exit 1;
	fi
	
	result=$( (git clone $git_user@$git_host:$git_repo clone) 2> /dev/null )
	if [ $? != 0 ]; then
	    (>&2 echo "$result")
	    (>&2 echo "Could not clone project \"$git_repo\". Aborting")
	    exit 1;
	fi
	cd "$script_dir/clone"
	if [ $? != 0 ]; then
	    (>&2 echo "Could not change dir to \"$script_dir/clone/\". Aborting")
	    exit 1;
	fi
	echo "Success: repository cloned"
	git_branch_current=""
	$( (git_branch_current=`git rev-parse --abbrev-ref HEAD`) 2> /dev/null)
	if [ $? != 0 ]; then
		git_branch_current=""
	    echo "Warning: could not get HEAD of current branch"
	    echo "Warning: current branch name is unknown"
	fi

	############################################
	# branch
	if [ "$git_branch_current" != "$git_branch" ]; then
		echo "captn_clone_local: changing branch"
		result=$( (git checkout $git_branch) 2> /dev/null )
		if [ $? != 0 ]; then
		    (>&2 echo "$result")
		    (>&2 echo "Could not change to branch \"$git_branch\". Aborting")
		    exit 1;
		fi
		echo "Success: checkout on branch \"$git_branch\""
	else
		echo "Success: already on branch \"$git_branch\""
	fi

	############################################
	# check current commit in $git_commit
	local commit="empty"
	if [ "$git_commit" != "" ]; then
		commit=$( (git cat-file -t $git_commit) 2> /dev/null )
	fi

	if [ "$git_commit" != "" ] && [ "$commit" != "commit" ]; then
		(>&2 echo "Invalid commit id \"$git_commit\"")
		git_commit=""
	fi
	# choose commit if necessary
	if [ "$git_commit" == "" ]; then
		commits=$(git log --pretty=format:"%H - %cn : %s" -$git_commit_limit)
		commit_head=$(git rev-parse HEAD)
		if [ "$commit_head" == "" ]; then
			echo "Warning: could not get last commit"
		else
			echo "Last commit is \"$commit_head\""
		fi
		echo "List of $git_commit_limit last commits:"
		echo "$commits"
		captn_commit $commit_head
	fi
	echo "$function_name: using commit id \"$git_commit\""

	############################################
	# generate changelog
	if [ "$git_commit_remote" == "" ]; then
	    echo "Warning: no information on the remote commit id of the server"
	    echo "No information in variable \$git_commit_remote"
	    captn_ask_continue
	else
		if [ "$git_commit_remote" == "$git_commit" ]; then
		    echo "Warning: targeted commit id \"$git_commit\" is already on the server"
		    captn_ask_continue
		else
			echo "$function_name: generating changelog"
			git log $git_commit_remote..$git_commit --pretty=format:"%H - %cn, %ad : %s"  > $script_dir/changelog.md
			if [ $? != 0 ]; then
			    echo "Warning: could not generate changelog in \"$script_dir/changelog.txt\""
			    captn_ask_continue
			elif [ -s $script_dir/changelog.txt ]; then
			    echo "Warning: changelog is empty in \"$script_dir/changelog.txt\""
			    echo "Warning: it is possible that updating the server could revert to a previous commit"
				captn_ask_continue
			else
				echo "Success: changelog generated in \"$script_dir/changelog.md\""
			fi
		fi
	fi

	echo "$function_name: updating local repository to commit \"$git_commit\""
	result=$( (git reset $git_commit --hard) 2> /dev/null )
	if [ $? != 0 ]; then
		(>&2 echo "$result")
		(>&2 echo "Could not update local repository to correct commit id \"$git_commit\". Aborting")
		exit 1;
	fi
	echo "Success: local repository updated"
}


function captn_choose_commit() {
	# choose commit if necessary
	if [ "$git_commit" == "" ]; then
		if [ ! -d "$script_dir/clone/" ]; then
			echo "Warning: no local repository found. Could not get commit list"
			captn_commit $git_commit_default
		else
			# get local commit list
			if [ "$git_commit_list" == "" ]; then
				git_commit_list=$(git log --pretty=format:"%H - %cn : %s" -$git_commit_limit)
			fi
			# get local HEAD commit id
			if [ "$git_commit_head" == "" ]; then
				git_commit_head=$(git rev-parse HEAD)
			fi
			if [ "$git_commit_head" == "" ]; then
				echo "Warning: could not get last commit"
			else
				echo "Last commit is \"$git_commit_head\""
			fi
			echo "List of $git_commit_limit last commits:"
			echo "$git_commit_list"
			captn_commit $git_commit_head
		fi
	fi
	if [ $? != 0 ]; then
		(>&2 echo "Error while choosing commit id. Aborting")
		exit 1;
	fi
	if [ "$git_commit" == "" ]; then
		echo "Warning: commit id is empty"
		if [ "$git_commit_default" == "" ]; then
			(>&2 echo "Default commit id is empty")
			return 1;
		fi
		exit 1;
	fi
	echo "captn_clone_local: using commit id \"$git_commit\""
}


#################################################
# Deploy local


function captn_deploy_local() {
	echo "captn_deploy_local: start"
	root="$script_dir/clone/"

	# composer update / install
#	if [ "$use_deploy_composer" == "1" ]; then;
#		captn_composer $root
#	fi

	# enable drupal 7/8 drush
#	if [ "$use_deploy_drush_enable" == "1" ]; then;
#		captn_drush_enable $root
#	fi
	
	# empty drupal 7/8 cache
#	if [ "$use_deploy_empty_cache" == "1" ]; then;
#		captn_drush_empty_cache $root
#	fi
}


#################################################
# Verify local


function captn_verify_local() {
	echo "captn_verify_local: start"
	root="$script_dir/clone/"

	# lint some files
}


#################################################
# Deploy remote


function captn_deploy_remote() {
	echo "captn_deploy_remote: start"
	root="$git_dir/"

	# compoer update / install
}


#################################################
# update remote

# Update 
function captn_update_git_remote() {
	function_name="captn_update_git_remote"
	captn_ask "Do you really want to deploy to the remote server" "no"
	if [ "$(captn_yes $response)" == "0" ]; then
	    (>&2 echo "User choose to Abort")
    	exit 1;
	fi

	echo "$function_name: connecting to $ssh_host:$ssh_port"
	{
		# eventually add git pull 
		ssh -tt -p $ssh_port $ssh_user@$ssh_host "cd $git_dir && git pull && git reset $git_commit --hard"
	} > $script_dir/remote_update.txt 2> /dev/null
	return_code=$?
	if [ $(grep -c "fatal" $script_dir/remote_update.txt) -ne 0 ]; then
		(>&2 cat $script_dir/remote_update.txt)
		(>&2 echo "$function_name: failed to update the remote server. Aborting")
		exit 1;
	fi
	if [ $return_code -ne 0 ]; then
		(>&2 echo "$function_name: failed to connect to SSH. Aborting.")
		exit 1;
	fi

	echo "Success: remote server updated"
}


#################################################
# Verify remote


function captn_verify_remote() {
	echo "captn_verify_remote: start"
	root="$git_dir/"

	# lint some files
}


#################################################
# Deploy

function captn_finish() {
	echo "capt_finish: start"
	# finish

}


#################################################
# General functions


function captn_commit() {
	# using first parameter for default commit or HEAD
	local default="HEAD"
	if [ $# == 1 ] && [ "$1" != "" ]; then
		default="$1"
	fi

	captn_ask "Commit Id to deploy" "$default"
	git_commit="$response"

	# verify commit id
	if [ -d "$script_dir/clone/" ]; then
		cd "$script_dir/clone/"
		local commit=$( (git cat-file -t $git_commit) 2> /dev/null )
		if [ "$commit" != "commit" ]; then
			(>&2 echo "Invalid commit id \"$git_commit\"")
			# loop unitil a correct commit is entered
			captn_commit
			return 0;
		fi
	fi
	return 0;
}


function captn_ask_continue() {
    captn_ask "Do you wish to continue" "yes"
    if [ "$(captn_yes $response)" == "0" ]; then
	    (>&2 echo "User choose to Abort")
    	exit 1;
    fi
    return 0
}


function captn_ask() {
	
	if [ "$2" != "" ]; then
		echo -en "$1 ($2)?"
	else		
		echo -en "$1?"
	fi

	read -e -p "\033" response

	if [ "$response" == "" ]; then
		response="$2"
	fi

	if [ $? != 0 ]; then
	    (>&2 echo "Response error")
	    return 1
	fi

	return 0
}


function captn_yes() {
	local yes=($script_true_values)
	array_contains yes $1 && echo "1" || echo "0"
	return 0
}


function array_contains() { 
    local array="$1[@]"
    local seeking=$2
    local in=1
    for element in "${!array}"; do
        if [[ $element == $seeking ]]; then
            in=0
            break
        fi
    done
    return $in
}





#######################################
# Start action "deploy-with-git-simple"

#######################################
# This script deploys on remote server using GIT with just the commit id

#######################################
# Start action "init"

#######################################
# Initialize some variables

#######################################
set -o pipefail
if [ $? != 0 ]; then
    (>&2 echo "Command failed. Aborting")
    exit 1;
fi

#######################################
set -o errtrace
if [ $? != 0 ]; then
    (>&2 echo "Command failed. Aborting")
    exit 1;
fi

#######################################
set -o nounset
if [ $? != 0 ]; then
    (>&2 echo "Command failed. Aborting")
    exit 1;
fi

#######################################
set -o errexit
if [ $? != 0 ]; then
    (>&2 echo "Command failed. Aborting")
    exit 1;
fi


# End action "init"

#######################################
captn_infos
if [ $? != 0 ]; then
    (>&2 echo "Command failed. Aborting")
    exit 1;
fi

#######################################
# Start action "clean"

#######################################
# delete files in cache directory of the script

#######################################
captn_clean
if [ $? != 0 ]; then
    (>&2 echo "Command failed. Aborting")
    exit 1;
fi


# End action "clean"

#######################################
captn_choose_commit
if [ $? != 0 ]; then
    (>&2 echo "Command failed. Aborting")
    exit 1;
fi

#######################################
# Start action "deploy-git-remote"

#######################################
# Start action "update-git-remote"

#######################################
captn_update_git_remote
if [ $? != 0 ]; then
    (>&2 echo "Command failed. Aborting")
    exit 1;
fi


# End action "update-git-remote"

#######################################
# Start action "install-remote"


# End action "install-remote"

#######################################
# Start action "verify-remote"


# End action "verify-remote"


# End action "deploy-git-remote"

#######################################
# Start action "test"

#######################################
# Testing that the site is working


# End action "test"


# End action "deploy-with-git-simple"
