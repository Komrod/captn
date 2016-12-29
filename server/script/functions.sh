
#################################################
#################################################
# Functions


#################################################
# Verify

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


#################################################
# Clean


# Function to clean temporary files
function captn_clean() {
	echo "captn_clean: Start cleaning directory"
	echo "captn_clean: script temp directory is \"$script_temp\""
	echo "captn_clean: deleting directory"
	rm -fr "$script_temp"
	# Check delete error
	if [ $? != 0 ]; then
		(>&2 echo "captn_clean: failed to delete directory. Aborting")
		exit 1;
	fi
	echo "captn_clean: recreating directory"
	mkdir "$script_temp"
	# Check creation error
	if [ $? != 0 ]; then
		(>&2 echo "captn_clean: failed to create directory. Aborting")
		exit 1;
	fi
	echo "Success: script temp directory cleaned"
}


#################################################
# Check remote


# Function to check remote server by SSH
function captn_check_remote() {
	echo "captn_check_remote: getting branch from remote server"
	echo "captn_check_remote: connecting to $ssh_host:$ssh_port"
	{
		ssh -tt -p $ssh_port $ssh_user@$ssh_host "cd $git_dir && git rev-parse --abbrev-ref HEAD && git rev-parse HEAD"
	} > $script_temp/remote.txt 2> /dev/null
	return_code=$?
	if [ $(grep -c "fatal" $script_temp/remote.txt) -ne 0 ]; then
		(>&2 cat $script_temp/remote_branch.txt)
		(>&2 echo "captn_check_remote: failed to get the remote branch name. Aborting")
		exit 1;
	fi
	if [ $return_code -ne 0 ]; then
		(>&2 echo "captn_check_remote: failed to connect to SSH. Aborting.")
		exit 1;
	fi
	# TODO apparently sometimes the first line is empty, must be sure
	line=1
	sed -n ${line}p $script_temp/remote.txt
	first_line=`sed -n ${line}p $script_temp/remote.txt`
	if [ "$first_line" == "" ]; then
		line=2
		first_line=`sed -n ${line}p $script_temp/remote.txt`
	fi
	git_branch_remote="$first_line" # `sed -n ${line}p $script_temp/remote.txt`
	line="$(($line+1))"
	git_commit_remote=`sed -n ${line}p $script_temp/remote.txt`
#echo "git_branch_remote = $git_branch_remote"
#echo "git_commit_remote = $git_commit_remote"
	len=$(echo ${#git_commit_remote})
	if [ "$git_commit_remote" == "" ] || [ $len -ne 40 ]; then
		(>&2 echo "captn_check_remote: invalid commit id \"$git_commit_remote\"")
		exit 1;
	fi
	if [ "$git_branch_remote" != "$git_branch" ]; then
		(>&2 echo "captn_check_remote: server branch \"$git_branch_remote\" in \"$git_dir\" is supposed to be \"$git_branch\".")
		exit 1;
	fi
	echo "Success: remote server branch is \"$git_branch_remote\""
	echo "Success: remote server last commit is \"$git_commit_remote\""
}


#################################################
# Clone


function captn_clone_local() {

	############################################
	# cloning
	echo "captn_clone_local: start"
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
	$( (git_branch_current=`git rev-parse --abbrev-ref HEAD`) 2> /dev/null)
	if [ $? != 0 ]; then
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
	echo "captn_clone_local: using commit id \"$git_commit\""

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
			echo "captn_clone_local: generating changelog"
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

	echo "captn_clone_local: updating local repository to commit \"$git_commit\""
	result=$( (git reset $git_commit --hard) 2> /dev/null )
	if [ $? != 0 ]; then
		(>&2 echo "$result")
		(>&2 echo "Could not update local repository to correct commit id \"$git_commit\". Aborting")
		exit 0;
	fi
	echo "Success: local repository updated"
}


#################################################
# Deploy local


function captn_deploy_local() {
	echo "captn_deploy_local: start"
	root="$script_temp/clone/"

	# compoer update / install
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


function captn_update_remote() {
	
	captn_ask "Do you really want to deploy to the remote server" "no"
	if [ "$()" == "0" ]; then
	    (>&2 echo "User choose to Abort")
    	exit 1;
	fi

	echo "captn_update_remote: connecting to $ssh_host:$ssh_port"
	{
		ssh -tt -p $ssh_port $ssh_user@$ssh_host "cd $git_dir && git reset $git_commit --hard"
	} > $script_temp/remote_update.txt 2> /dev/null
	return_code=$?
	if [ $(grep -c "fatal" $script_temp/remote.txt) -ne 0 ]; then
		(>&2 cat $script_temp/remote_branch.txt)
		(>&2 echo "captn_update_remote: failed to update the remote server. Aborting")
		exit 1;
	fi
	if [ $return_code -ne 0 ]; then
		(>&2 echo "captn_update_remote: failed to connect to SSH. Aborting.")
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
	if [ "$1" != "" ]; then
		default="$1"
	fi

	captn_ask "Commit Id to deploy" "$default"
	git_commit="$response"

	# verify commit id
	cd "$script_temp/clone/"
	local commit=$( (git cat-file -t $git_commit) 2> /dev/null )
	if [ "$commit" != "commit" ]; then
		(>&2 echo "Invalid commit id \"$git_commit\"")
		# loop unitil a correct commit is entered
		captn_commit
		return 0;
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


