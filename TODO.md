## TODO

- make a changelog action
- captn list must only show .json files
- bug: captn list dont show complete script name
- action to test SSH
- action to test GIT
- retrieve GIT project by http url (github like)

- put the action name in the shell script file
- take a script by default if there is only one
- cli option to change script variables
- cli option to confirm every action execution
- "if" in command option
- cli option "-y" to say yes to everything in batch mode
- detects actions infinite loop on explain
- handle infinite loop of actions (level depth)
- function to ask a response on a selected list
- cli command "build" to return script in stdout (-o) or just write script
- cli command "diagnose"
- lint the shell scripts before running (if possible)
- readme describes captn functions

- dont show empty actions on cli command "explain"
- function to disable / enable "ctrl-c"
- console show default answer when pressing enter in captn_ask
- put colors directly in script
- possible to run directly the script
- readme describes main actions and sub actions
- show commits with current colored in function captn_commit
- script warning on multiple lines
- optional choose ssh command in captn config


## DONE

- v0.1.2
- add logo and console image
- make an action to clean everything, even the cloned directory
- fix: creation of script cache dir "script_dir"
- dont delete the cloned repository of the script everytime we clean
- v0.1.1
- tweak deploy with git
- fix: clean action doe not delete all the files
- deleting script variable git_dir
- echoBefore command option
- continue on error command option
- add echoOnError and echoOnSuccess
- fix captn init
- fix output in stdout sometimes does not render when exiting
- disable log for init
- v0.1.0
- command line "explain"
- optional generate archive in remote in script config
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

