# captn

Easy web server deployment


## TODO

- optional generate archive in remote in script config
- optional generate changelog in captn config
- command line "explain"
- command line "diagnose"
- make a changelog action
- command line "build" to return script (-o) or write script
- continue on error command option

- command line option to change script variables
- command line option to confirm every action execution
- "if" in command option
- pass program parameters to script
- bug: captn list dont show complete script name
- captn list must only show .json files
- cli "-y" option to say yes to everything in batch mode
- function to ask a response on a selected list
- generate and store the diff of the code
- optional generate changelog in captn config
- console show default answer when pressing enter in captn_ask
- dont delete the cloned repository of the script
- make an action to clean everything, even the cloned directory
- action to test SSH
- lint the shell scripts before running
- command to build script
- put colors directly in script
- describe main actions and sub actions in readme
- show commits with current colored in captn_commit
- script warning on multiple lines
- ignore log of some strings with regex
- optional choose ssh command in captn config


## DONE

- add $FUNCNAME in start of echo
- write logs
- change "temp" to "cache"
- include files in shell script
- extend script actions from default captn json script
- error check step
- update remote server step
- multiple actions in one script
- create one action for every step
- pass to shell all the variables inside script config except object
- skip checking remote commit if git_commit_remote is filled
- message "press [ctrl-c] at any time to quit"
- function to ask if you want to continue
- function to ask a question
- cloning step
- show questions
- redirect stdin
- optional skip command
- Delay before continuing at startup
- Make the variables
- Make the functions
- Show warning message at startup
- Build script
- Show warning in yellow and success in green


## In shell

script_json: absolute path for the json file of the script
script_sh: absolute path for the sh file of the script
script_name: name of the script
script_target: target directory of the site to deploy
script_date: current date
script_temp: temporary directory for the script

git_host:
git_user:
git_branch_remote:
git_branch:
git_commit:
git_commit_remote:

ssh_host:
ssh_port:
ssh_user:

skip_check: if true value, skip the captn_git_check
skip_patch: if true value, skip the captn_git_patch and captn_apply
skip_deploy: if true value, skip the captn_deploy

captn_dir: root directory of captn
captn_version: version of captn


true values: "y", "Y", "yes", "Yes", "YES", "1", "true", "ok", "yep"


## Functions

captn_start: function to display informations, warning at startup
captn_clean: function to clean temporary directory and files
captn_check: function to check if git branch is ready
captn_patch: function to get the patch between the 2 branches
captn_deploy: function to apply patch to 


## Git example

```
	git rev-parse HEAD 
	# get last commit id
	
	git log edcfc6184b5cb30e29c0da3ccdec296379d3c7b8..0efeb3800396e15717b4f15fb572f5886fa49c50  --pretty=format:"%H - %cn, %ad : %s" 
	# get list of commits to update
	
	git cat-file -t 0efeb3800396e15717b4f15fb572f5886fa49c51 
	# check if commit exists
```


