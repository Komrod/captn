



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

# Function to clean local temporary files
function captn_clean() {
	local function_name="captn_clean"
	echo "$function_name: Start cleaning"
	echo "$function_name: script temp directory is \"$script_temp\""
	echo "$function_name: deleting all files in directory"
	rm -fr "$script_temp/*.*"
	# Check delete error
	if [ $? != 0 ]; then
		(>&2 echo "$function_name: failed to delete directory. Aborting")
		exit 1;
	fi
	echo "Success: script temporary files cleaned"
}

# Function to delete and recreate local temporary directory
function captn_clean_all() {
	local function_name="captn_clean_all"
	echo "$function_name: Start cleaning"
	echo "$function_name: script temp directory is \"$script_temp\""
	echo "$function_name: deleting directory"
	rm -fr "$script_temp"
	# Check delete error
	if [ $? != 0 ]; then
		(>&2 echo "$function_name: failed to delete directory. Aborting")
		exit 1;
	fi
	echo "$function_name: recreating directory"
	mkdir "$script_temp"
	# Check creation error
	if [ $? != 0 ]; then
		(>&2 echo "$function_name: failed to create directory. Aborting")
		exit 1;
	fi
	echo "Success: script temp directory cleaned"
}

# Function to delete the cloned repository
function captn_clean_clone() {
	local function_name="captn_clean_clone"
	echo "$function_name: Start cleaning cloned directory"
	echo "$function_name: script temp directory is \"$script_temp\""
	echo "$function_name: deleting cloned directory"
	rm -fr "$script_temp/clone/"
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
	} > $script_temp/remote.txt 2> /dev/null
	return_code=$?
	if [ $(grep -c "fatal" $script_temp/remote.txt) -ne 0 ]; then
		(>&2 cat $script_temp/remote_branch.txt)
		(>&2 echo "$function_name: failed to get the remote branch name. Aborting")
		exit 1;
	fi
	if [ $return_code -ne 0 ]; then
		(>&2 echo "$function_name: failed to connect to SSH. Aborting.")
		exit 1;
	fi

	line=1
	first_line=`sed -n ${line}p $script_temp/remote.txt`
	if [ "$first_line" == "" ]; then
		line=2
		first_line=`sed -n ${line}p $script_temp/remote.txt`
	fi
	git_branch_remote="$first_line" # `sed -n ${line}p $script_temp/remote.txt`
	line="$(($line+1))"
	git_commit_remote=`sed -n ${line}p $script_temp/remote.txt`
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
	cd "$script_temp"
	if [ $? != 0 ]; then
	    (>&2 echo "Could not change dir to \"$script_temp\". Aborting")
	    exit 1;
	fi
	
	result=$( (git clone $git_user@$git_host:$git_repo clone) 2> /dev/null )
	if [ $? != 0 ]; then
	    (>&2 echo "$result")
	    (>&2 echo "Could not clone project \"$git_repo\". Aborting")
	    exit 1;
	fi
	cd "$script_temp/clone"
	if [ $? != 0 ]; then
	    (>&2 echo "Could not change dir to \"$script_temp/clone/\". Aborting")
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
			git log $git_commit_remote..$git_commit --pretty=format:"%H - %cn, %ad : %s"  > $script_temp/changelog.md
			if [ $? != 0 ]; then
			    echo "Warning: could not generate changelog in \"$script_temp/changelog.txt\""
			    captn_ask_continue
			elif [ -s $script_temp/changelog.txt ]; then
			    echo "Warning: changelog is empty in \"$script_temp/changelog.txt\""
			    echo "Warning: it is possible that updating the server could revert to a previous commit"
				captn_ask_continue
			else
				echo "Success: changelog generated in \"$script_temp/changelog.md\""
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
		if [ ! -d "$script_temp/clone/" ]; then
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
	root="$script_temp/clone/"

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
	root="$script_temp/clone/"

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
		ssh -tt -p $ssh_port $ssh_user@$ssh_host "cd $git_dir && git reset $git_commit --hard"
	} > $script_temp/remote_update.txt 2> /dev/null
	return_code=$?
	if [ $(grep -c "fatal" $script_temp/remote_update.txt) -ne 0 ]; then
		(>&2 cat $script_temp/remote_update.txt)
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
	if [ -d "$script_temp/clone/" ]; then
		cd "$script_temp/clone/"
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


