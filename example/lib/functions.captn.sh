



#################################################
#################################################
# Functions


#################################################
# Start with some informations about the script

# Function to show informations on startup
function captn_infos() {
	echo "$FUNCNAME: script \"$script_name\""
	echo "$FUNCNAME: $script_description"
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
	echo "$FUNCNAME: Start cleaning"
	echo "$FUNCNAME: script cache directory is \"$script_dir\""
	echo "$FUNCNAME: deleting all files in cache directory"
	cd "$script_dir"
	if [ $? != 0 ]; then
		(>&2 echo "$FUNCNAME: failed to change directory to \"$script_dir\". Aborting")
		exit 1;
	fi

	local files=(`captn_dir_files ./`)
	local num=${#files[@]}
	echo "$FUNCNAME: found $num file(s)"
	if [ $num -ne 0 ]; then
		for i in "${files[@]}"; do
			rm "$i"; 
		done
	fi
	# Check delete error
	if [ $? != 0 ]; then
		(>&2 echo "$FUNCNAME: failed to delete files. Aborting")
		exit 1;
	fi
	local files=(`captn_dir_files ./`)
	if [ ${#files[@]} -ne 0 ]; then
		(>&2 echo "$FUNCNAME: failed to delete all the files. Aborting")
		exit 1
	fi
	echo "Success: script cache files cleaned"
	return 0
}


# Function to delete and recreate local cache directory
function captn_clean_all() {
	echo "$FUNCNAME: Start cleaning"
	echo "$FUNCNAME: script cache directory is \"$script_dir\""
	echo "$FUNCNAME: deleting cache directory"
	if [ ! -d "$script_dir" ]; then
		(>&2 echo "$FUNCNAME: failed to find cache directory. Aborting")
		exit 1;
	fi
	rm -fr "$script_dir"
	# Check delete error
	if [ $? != 0 ]; then
		(>&2 echo "$FUNCNAME: failed to delete directory. Aborting")
		exit 1;
	fi
	if [ -d "$script_dir" ]; then
		(>&2 echo "$FUNCNAME: failed to delete directory. Aborting")
		exit 1;
	fi
	echo "$FUNCNAME: recreating directory"
	mkdir "$script_dir"
	# Check creation error
	if [ $? != 0 ]; then
		(>&2 echo "$FUNCNAME: failed to create directory. Aborting")
		exit 1;
	fi
	if [ ! -d "$script_dir" ]; then
		(>&2 echo "$FUNCNAME: failed to create directory. Aborting")
		exit 1;
	fi
	echo "Success: script cache directory cleaned"
}


# Function to delete the repository directory
function captn_clean_repo() {
	echo "$FUNCNAME: Start cleaning repository directory"
	echo "$FUNCNAME: script cache directory is \"$script_dir\""
	echo "$FUNCNAME: deleting repository directory"
	if [ ! -d "$script_dir/repo/" ]; then
		echo "Warning: no repository directory"
	fi
	rm -fr "$script_dir/repo/"
	# Check delete error
	if [ $? != 0 ]; then
		(>&2 echo "$FUNCNAME: failed to delete directory. Aborting")
		exit 1;
	fi
	echo "Success: script repository directory deleted"
	return 0
}


#################################################
# GIT


# Function to check GIT project directory on remote server by SSH
function captn_check_git_remote() {
	echo "$FUNCNAME: getting branch from remote server"
	echo "$FUNCNAME: connecting to $ssh_host:$ssh_port"
	{
		ssh -tt -p $ssh_port $ssh_user@$ssh_host "cd $remote_dir && git rev-parse --abbrev-ref HEAD && git rev-parse HEAD"
	} > $script_dir/remote.txt 2> /dev/null
	return_code=$?
	if [ $(grep -c "fatal" $script_dir/remote.txt) -ne 0 ]; then
		(>&2 cat $script_dir/remote.txt)
		(>&2 echo "$FUNCNAME: failed to get the remote branch name. Aborting")
		exit 1;
	fi
	if [ $return_code -ne 0 ]; then
		(>&2 echo "$FUNCNAME: failed to connect to SSH. Aborting.")
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
		(>&2 echo "$FUNCNAME: invalid commit id \"$git_commit_remote\"")
		exit 1;
	fi
	if [ "$git_branch_remote" != "$git_branch" ]; then
		(>&2 echo "$FUNCNAME: server branch \"$git_branch_remote\" in \"$remote_dir\" is supposed to be \"$git_branch\".")
		exit 1;
	fi
	echo "Success: remote server branch is \"$git_branch_remote\""
	echo "Success: remote server last commit is \"$git_commit_remote\""
}


function captn_archive_remote() {
	echo "$FUNCNAME: start"
	echo "$FUNCNAME: connecting to $ssh_host:$ssh_port"
	local now=$(date +"%Y-%d-%m-%T")
	now=$(echo $now | sed -e "s/\:/\-/g")
	captn_ssh "cd $archive_dir && $archive_command ${archive_dir}${archive_name}_${now}${archive_extension} ${remote_dir}"
	if [ $? != 0 ]; then
	    (>&2 echo "Could not create archive. Aborting")
	    exit 1;
	fi

	echo "$FUNCNAME: archive created as ${archive_dir}${archive_name}_${now}${archive_extension}"
	echo "Success: archive created"
}


# Clone project on local machine if repository directory not already created
function captn_repo_local() {

	echo "$FUNCNAME: start"

	if [ ! -d $script_dir ]; then
	    (>&2 echo "Could not find cache directory \"$script_dir\". Aborting")
	    exit 1;
	fi
	
	if [ -d "$script_dir/repo/" ]; then
		echo "$FUNCNAME: repository directory already exists"

		cd "$script_dir/repo/"
		if [ $? != 0 ]; then
		    (>&2 echo "Could not change to dir \"$script_dir/repo/\". Aborting")
		    exit 1;
		fi

		result=$( (git status) 2> /dev/null )
		if [ $? != 0 ]; then
		    echo "Warning: could not get status of dir \"$script_dir/repo/\""
		    echo "$FUNCNAME: deleting invalid repository directory"
		    captn_clean_repo
		    echo "Success: repository directory deleted"
		fi
	fi

	cd "$script_dir"
	if [ $? != 0 ]; then
	    ( >&2 echo "Warning: could not change directory to \"$script_dir/\". Aborting")
	    exit 1
	fi

	if [ ! -d "$script_dir/repo/" ]; then
		result=$( (git clone $git_user@$git_host:$git_repo repo) 2> /dev/null )
		if [ $? != 0 ]; then
		    (>&2 echo "$result")
		    (>&2 echo "Could not clone project \"$git_repo\". Aborting")
		    exit 1;
		fi
		cd "$script_dir/repo"
		if [ $? != 0 ]; then
		    (>&2 echo "Could not change dir to \"$script_dir/repo/\". Aborting")
		    exit 1;
		fi
		echo "Success: repository cloned"
	fi

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

		cd "$script_dir/repo/"
		if [ $? != 0 ]; then
		    (>&2 echo "Could not change to dir \"$script_dir/repo/\". Aborting")
		    exit 1;
		fi
		echo "$FUNCNAME: changing branch $git_branch"
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
}


# Choose the commit and set local project to commit id
function captn_choose_commit() {
	# choose commit if necessary
	echo "$FUNCNAME: start"

	if [ "$git_commit" == "" ]; then
		if [ ! -d "$script_dir/repo/" ]; then
			echo "Warning: no local repository found. Could not get commit list"
			captn_commit $git_commit_default
		else
			cd "$script_dir/repo/"
			if [ $? != 0 ]; then
				sleep 0.001
				(>&2 echo "Could not change to repository directory. Aborting")
				exit 1;
			fi
			# pull
			echo "$FUNCNAME: git pull"
			result=$( (git pull) 2> /dev/null )
			if [ $? != 0 ]; then
			    (>&2 echo "$result")
			    (>&2 echo "Could not pull. Aborting")
			    exit 1;
			fi
			# get local commit list
			if [ "$git_commit_list" == "" ]; then
				echo "$FUNCNAME: get the commit list"
				git_commit_list=$(git log --pretty=format:"%H - %cn : %s" -$git_commit_limit)
			fi
			# get local HEAD commit id
			if [ "$git_commit_head" == "" ]; then
				echo "$FUNCNAME: get the branch HEAD"
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
	echo "$FUNCNAME: using commit id \"$git_commit\""

}


# Choose the commit ids to use with changelog and store it in $git_commit_remote and $git_commit
function captn_choose_changelog() {
	echo "$FUNCNAME: start"
	if [ ! -d "$script_dir/repo/" ]; then
		echo "Warning: no local repository found. Could not get commit list"
	else
		cd "$script_dir/repo/"
		if [ $? != 0 ]; then
			sleep 0.001
			(>&2 echo "Could not change to repository directory. Aborting")
			exit 1;
		fi
		# pull
		echo "$FUNCNAME: git pull"
		result=$( (git pull) 2> /dev/null )
		if [ $? != 0 ]; then
		    (>&2 echo "$result")
		    (>&2 echo "Could not pull. Aborting")
		    exit 1;
		fi

		# get local commit list
		if [ "$git_commit_list" == "" ]; then
			echo "$FUNCNAME: get the commit list"
			git_commit_list=$(git log --pretty=format:"%H - %cn : %s" -$git_commit_limit)
		fi
		# get local HEAD commit id
		echo "List of $git_commit_limit last commits:"
		echo "$git_commit_list"
	fi

	captn_ask "Commit id from"
	git_commit_remote="$response"
	if [ $? != 0 ]; then
		(>&2 echo "Error while choosing commit id. Aborting")
		exit 1;
	fi
	captn_ask "Commit id to"
	git_commit="$response"
	if [ $? != 0 ]; then
		(>&2 echo "Error while choosing commit id. Aborting")
		exit 1;
	fi

	echo "$FUNCNAME: using commit ids \"$git_commit_remote..$git_commit\""
}


# Update local GIT to commits id $1
# use: captn_update_local d20ba56cbe573ee7e25d1c02e9be41165263dba9
# Warning on: 
# Error on: no update
# Critical error on: 
function captn_update_local() {
	echo "$FUNCNAME: start"
	local file="$script_dir/changelog.txt"
	numargs="$#"
	if [ $numargs != "1" ]; then
		sleep 0.001
		(>&2 echo "Invalid number of arguments to update local repository")
		return 1;
	fi

	captn_is_commit $1
	if [ $? == 1 ]; then
		sleep 0.001
		(>&2 echo "Invalid commit id \"$1\"")
		(>&2 echo "Unable to update local repository")
		return 1;
	fi

	result=$( (git reset $git_commit --hard) 2> /dev/null )
	if [ $? != 0 ]; then
		(>&2 echo "$result")
		(>&2 echo "Could not update local repository to correct commit id \"$1\"")
		return 1;
	fi

	echo "Success: local repository update to commit id \"$1\""
	return 0;
}


# Generate changelog.md between commits id $1 and $2
# use: captn_changelog d20ba56cbe573ee7e25d1c02e9be41165263dba9 af08a57a08f98bc9ac89a51f163fc6dd087fbd6c
# Warning on: could not generate changelog, changelog is empty
# Error on: invalid commit id, invalid arguments
# Critical error on: could not delete old changelog
# prompt: continue on warning or error
function captn_changelog() {
	echo "$FUNCNAME: start"
	local file="$script_dir/changelog.txt"
	numargs="$#"
	if [ $numargs != "2" ]; then
		sleep 0.001
		(>&2 echo "Invalid number of arguments to generate the changelog")
	    echo "Warning: could not generate changelog in \"$file\""
	    captn_ask_continue
		return 0;
	fi

	echo "$FUNCNAME: changelog from \"$1\" to \"$2\""

	captn_is_commit $1
	if [ $? == 1 ]; then
		sleep 0.001
		(>&2 echo "Invalid commit id \"$1\"")
	    echo "Warning: could not generate changelog in \"$file\""
	    captn_ask_continue
		return 0;
	fi

	captn_is_commit $2
	if [ $? == 1 ]; then
		sleep 0.001
		(>&2 echo "Invalid commit it \"$2\"")
	    echo "Warning: could not generate changelog in \"$file\""
	    captn_ask_continue
	    return 0;
	fi


	if [ -f $file ]; then
		rm "$file"
		if [ $? != 0 ]; then
			sleep 0.001
			(>&2 echo "Could not delete old changelog file \"$file\"")
		    echo "Warning: could not generate changelog in \"$file\""
		    captn_ask_continue
			return 1;
		fi
	fi
	
	echo "$FUNCNAME: generating"

	git log $1..$2 --pretty=format:"%H - %cn, %ad : %s"  > $file
	local filesize=$(stat -c%s "$file")
	if [ $? != 0 ]; then
	    echo "Warning: could not generate changelog in \"$file\""
	    captn_ask_continue
	elif [ $filesize -eq 0 ]; then
	    echo "Warning: changelog is empty in \"$file\""
	    captn_ask_continue
	    return 0;
	else
		local file_md="$script_dir/changelog.md"
		echo "## Changelog - date $script_date" > $file_md
		echo "" >> $file_md
		cat $file >> $file_md

		if [ $? != 0 ]; then
		    echo "Warning: could not generate changelog in \"$file_md\""
		    return 1;
		fi
		echo ""
		echo "Success: changelog generated in \"$file_md\""
		return 0;
	fi
	return 0;
}


#################################################
# Deploy local


function captn_deploy_local() {
	echo "$FUNCNAME: start"
	root="$script_dir/repo/"

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
	echo "$FUNCNAME: start"
	root="$script_dir/repo/"

	# lint some files
}


#################################################
# Deploy remote


function captn_deploy_remote() {
	echo "$FUNCNAME: start"
	root="$remote_dir/"

	# composer update / install
}


#################################################
# update remote

# Update 
function captn_update_git_remote() {
	echo "$FUNCNAME: start"
	captn_ask "Do you really want to deploy to the remote server" "no"
	if [ "$(captn_yes $response)" == "0" ]; then
	    (>&2 echo "User choose to Abort")
    	exit 1;
	fi

	echo "$FUNCNAME: connecting to $ssh_host:$ssh_port"
	{
		# eventually add git pull 
		ssh -tt -p $ssh_port $ssh_user@$ssh_host "cd $remote_dir && git pull $git_user@$git_host:$git_repo $git_branch && git reset $git_commit --hard"
	} > $script_dir/remote_update.txt 2> /dev/null
	return_code=$?
	if [ $(grep -c "fatal" $script_dir/remote_update.txt) -ne 0 ]; then
		(>&2 cat $script_dir/remote_update.txt)
		(>&2 echo "$FUNCNAME: failed to update the remote server. Aborting")
		exit 1;
	fi
	if [ $return_code -ne 0 ]; then
		(>&2 echo "$FUNCNAME: failed to connect to SSH. Aborting.")
		exit 1;
	fi

	echo "Success: remote server updated"
}


#################################################
# Verify remote


function captn_verify_remote() {
	echo "$FUNCNAME: start"
	root="$remote_dir/"

	# lint some files
}


#################################################
# Deploy

function captn_finish() {
	echo "$FUNCNAME: start"
	# finish

}


#################################################
# General functions


# Return 1 if a commit id $1 is valid for the current repository local project 
# use: captn_is_commit af08a57a08f98bc9ac89a51f163fc6dd087fbd6c
# use: if [ captn_is_commit HEAD ]; then ...
# Warning on: no repository dir
function captn_is_commit() {
	numargs="$#"
	if [ $numargs != "1" ]; then
		sleep 0.001
		(>&2 echo "Invalid number of arguments to verify commit")
		return 1;
	fi

	echo "$FUNCNAME: verify commit id \"$1\""	

	if [ ! -d "$script_dir/repo/" ]; then
		echo "Warning: No repository directory in script cache directory. Could not verify commit id"
		return 1;
	fi
	
	cd "$script_dir/repo/"
	if [ $? != 0 ]; then
		sleep 0.001
		echo "Warning: Could not change to repository directory. Could not verify commit id"
		return 1;
	fi

	local commit="empty"
	commit=$( (git cat-file -t $1) 2> /dev/null )

	if [ "$commit" != "commit" ]; then
		return 1;
	fi
	return 0;
}


function captn_ssh() {
	echo "$FUNCNAME: Connecting to SSH"
	echo "$FUNCNAME: Executing command \"$1\""
	local cmd=$1
	{
		ssh -tt -p $ssh_port $ssh_user@$ssh_host $cmd
	} > $script_dir/remote.txt 2> /dev/null
	echo "$FUNCNAME: generated file remote.txt"
	if [ $? != 0 ]; then
	    (>&2 cat $script_dir/remote.txt)
	    (>&2 echo "Error while connecting to SSH server or executing the command")
	    return 1
	fi
	result=$(cat $script_dir/remote.txt)
	return 0
}


function captn_commit() {
	# using first parameter for default commit or HEAD
	local default="HEAD"
	if [ $# == 1 ] && [ "$1" != "" ]; then
		default="$1"
	fi

	captn_ask "Commit Id to deploy" "$default"
	git_commit="$response"

	# verify commit id
	if [ -d "$script_dir/repo/" ]; then
		cd "$script_dir/repo/"
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


# echo "1" if the parameter can interprete as true (values listed in $scipt_true_values)
# use: captn_yes $response
# use: if [ "$(captn_yes $value)" == "1" ] then; ...
function captn_yes() {
	local yes=($script_true_values)
	array_contains yes $1 && echo "1" || echo "0"
	return 0
}


# echo "1" if the $1 parameter is in list $2 parameter
function captn_in_list() {
	local list=($2)
	array_contains list $1 && echo "1" || echo "0"
	return 0
}

# return 1 if the
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

function captn_dir() {
	if [ ! -d "$1" ]; then
		return 1;
	fi
	echo $(ls -A $1)
	return 0;
}

function captn_dir_files() {
	if [ ! -d "$1" ]; then
		return 1;
	fi
	local files=$(ls -A $1)
	local list=($files)
	if [ ${#list[@]} -eq 0 ]; then
		return 0;
	fi
	for i in "${list[@]}"; do
		if [ ! -d "$1/$i" ]; then
			echo "$i"
		fi
	done
	return 0;
}

function captn_dir_dirs() {
	if [ ! -d "$1" ]; then
		returnexit 1;
	fi
	local files=$(ls -A $1)
	local list=($files)
	for i in "${list[@]}"; do
		if [ -d "$1/$i" ]; then
			echo "$i"
		fi
	done
	return 0;
}

