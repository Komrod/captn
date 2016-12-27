# captn
Easy web server production deployment


TODO:
- connect SSH with public and private keys
- multiple actions in one script
- Continue on error
- Show warning message at startup
- Wait for delay at startup
- Make the variables
- Make the functions
- Declare variables server side in SSH


DONE:
- Build script
- Show warning in yellow and success in green



In commands:

script_json: absolute path for the json file of the script
script_sh: absolute path for the sh file of the script
script_name: name of the script
script_target: target directory of the site to deploy
script_date: current date
script_temp: temporary directory for the script

git_host:
git_user:
git_branch_from:
git_branch_to:

ssh_host:
ssh_port:
ssh_user:

skip_check: if true value, skip the captn_git_check
skip_patch: if true value, skip the captn_git_patch and captn_apply
skip_deploy: if true value, skip the captn_deploy

captn_dir: root directory of captn
captn_version: version of captn


true values: "y", "Y", "yes", "Yes", "YES", "1", "true"


Functions:
captn_start: function to display informations, warning at startup
captn_clean: function to clean temporary directory and files
captn_check: function to check if git branch is ready
captn_patch: function to get the patch between the 2 branches
captn_deploy: function to apply patch to 

Git example:
git rev-parse HEAD // get last commit id
git log edcfc6184b5cb30e29c0da3ccdec296379d3c7b8..0efeb3800396e15717b4f15fb572f5886fa49c50  --pretty=format:"%H - %cn, %ad : %s" // get list of commits to update
git cat-file -t 0efeb3800396e15717b4f15fb572f5886fa49c51 // check if commit exists


Steps:
# Start
- infos about the script
- warning
- delay before continue
# clean
- delete temp dir and files
# check
- connect to server by SSH
- get branch and last commit
- local: init git to HEAD of branch
- local: choose the commit id to update to
- local: get the log list of commits to update
- local: update to selected commit and finish
# deploy
- connect to server by SSH 
- update to selected commit


