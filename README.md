# Captn

Easy web server deployment

This is a prototype.

For the moment, it deploys only GIT content but captn is easy to modify by adding your own commands when you want them or using captn built-in functions.

*Features include:*
- Ask for commit id to deploy
- Verify commit id with GIT server on client machine
- Clone and verify project on client machine
- Archive on remote server
- Deploy on remote from the GIT server
- Log everything
- Stop script on critical error


## Requires

Captn will run on Linux and Windows as long as you have those things:
- Bash shell commands on client machine and remote server
- Node on client machine
- GIT on client machine and remote server
- SSH access to remote server and to GIT
- Installed SSH keys to autoconnect from client machine and from remote server


It's pretty standard for Linux. On windows, you can install GIT bash that will provide GIT commands and Bash shell when you launch a Bash console.


There is many ways to configure captn and deploy your project on the server.


The GIT and SSH users are configured in the script config json file. It is highly recommanded that an auto connection is configured for GIT and SSH users otherwise the scripts can stop on password prompt or may be not work at all, who knows.

You can also configure your script to ask for a GIT login or SSH login if you want.
Additional behaviors can be added as shell commands, functions or calls to captn actions.


## Quick start

### Install

Install with npm:

```
	npm install -g node-captn
```
It is recommanded that you install globaly so you can run captn from anywhere.

### Make your own project

You can then initialize your script project. Simply create a directory, go inside it and run "captn init" :

```
	mkdir kirk
	cd kirk
	captn init
```

This will create the directories and files to run default actions and commands.

```
	- lib/
		- functions.captn.sh 
		- script.captn.json
	- log/
		- captn.log
	- script/
		- example.json
	- captn.json
```

### Edit and run

You can now edit the file "script/example.json" to complete with your own informations.

Feel free to create a new .json file in the "script/" directory. The new script will appear if you run "captn list".
Remember that all the actions by default are extended from "lib/script.captn.json". You can override them in your user script file.

If you configure correctly the variables inside your .json file (GIT, SSH ...), you will be able to connect automatically to the server by SSH.

Running the script

```
	captn run example
```
This will run the default script.

```
	captn run example:archive-remote
```
This will create an archive in the remote server to save the data if needed.
For beginners or when you are developping your script, it is recommanded to use the verbose option "-v"
```
	captn run example:archive-remote -v
```
This will show extra output to explain what is going on.


## Deploy methods

### deploy-with-git

Deploys the GIT repository content as it is with verification of branch, commit ids on local machine and remote server


Run the script like this:
```
	captn run example:deploy-with-git
```
Or put the action ":deploy-with-git" in the default action then run it like this:
```
	captn run example
```

#### Required in the script json file
- Filled GIT details (git_hst, git_user, git_repo, git_branch)
- Filled SSH details (ssh_host, ssh_port, ssh_user)

#### Required on local machine and remote server
- SSH auto connect for GIT and SSH users from local machine
- SSH auto connect for GIT user from remote server
- Remote final directory (remote_dir) must be a GIT directory

#### The steps
```
1 - Connecting to the remote server to get the last commit id and check the branch
2 - Cloning project / using the cloned directory on local machine
3 - Choose the commit id to update to
4 - Generate changelog from last commit id to new commit id
5 - Update the remote server after being pretty sure everything is fine
6 - Do some test to see the server is still working (if provided)
```


If you want to test some urls in the end, you should add your own commands to the ":test" action.

When you are choosing the commit id, you can see the list of commit id to choose from if you are running in verbose mode:
```
	captn -v run example:deploy-with-git
```

### deploy-with-git-simple

Deploys the GIT repository content as it is without verifications


Run the script like this:
```
	captn run example:deploy-with-git-simple
```
Or put the action ":deploy-with-git-simple" in the default action then run it like this:
```
	captn run example
```

#### Required in the script json file
- Filled GIT details (git_hst, git_user, git_repo, git_branch)
- Filled SSH details (ssh_host, ssh_port, ssh_user)

#### Required on local machine and remote server
- SSH auto connect for SSH user from local machine
- SSH auto connect for GIT user from remote server
- Remote final directory (remote_dir) must be a GIT directory


#### The steps
```
1 - Choose the commit id to update to (no list)
2 - Update the remote server (without much verifications)
3 - Do some test to see the server is still working (if provided)
```

If you want to test some urls in the end, you should add your own commands to the ":test" action.


## Other interesting actions

### archive-remote

Figure out how it works yourself.


### Share the project by GIT

Your captn project with your scripts can be store on a GIT repository and shoared with many developpers. Depending on what user can connect to the remote server, you can esaily handle security on who can deploy.


## captn commands

When you are in the root directory of your project, you can run the captn commands. For example, run command "captn list" in the shell will display the list of available scripts

### list

```
	captn list
```

Show a list of scripts. Each script can be configured to deploy a project on a server.
Each script name corresponds to a json file inside the script directory, by default "script/".

### run

```
	captn run <script-name>
	captn run <script-name>:<action-name>
```

If you omit the action, the default action is executed

### Explain

```
	captn explain <script-name>
	captn explain <script-name>:<action-name>
```

This command take the first comment of every actions that is launched by the selected script action. Execute "captn explain script-name" to see the explanation of the default action. Execute "captn explain script-name:action-name" to see the explanation of a particular action.

### Options

You can add an option when you run captn.

### Verbose: -v or --verbose

Show more text on the console on what is going on.


## How to cutomize your script

### Just adding a simple command

You can add a simple command just by adding 

```
	...
	"actions": {
		"my-action": [
			""
		],
		...
	}
```

By default, every command return code is checked. If the command return code is 0, it's a success and it will continue. If the command returns something else (usually 1), the script will show an error and exit.

For example, if you run "cd /i-dont-exist/", it will show an error and return the exit code 1, so the script will detect that there is a problem with the previous command and exit, preventing from doing harm.
You can continu on error by doing a more complex command with options (example below).

### Use global variables

You can use all the variables inside your .json script file in your commands (except the action list). Just use "$" and the name of the variable.
In your .json file "script_cache" is

```
	...
	"actions": {
		"my-action": [
			"cd $script_cache"
		],
		...
	}
```

Remember that when changing current directory on local machine, it will keep it as the current directory for the rest of the script until changed.
If you want to be sure to be on the right directory, just use "cd" command on the beginning of your action.

### Echo warning Error Success

You can display Warning in yellow, error in red and success uin green in the console. Showing an error will not exit the script. 
Warnings, errors and success are visible without the verbose mode. All others are invisible unless you use the verbose mode "captn run example -v".

```
	...
	"actions": {
		"my-action": [
			"echo "Warning: this is a warning",
			"echo "Error: this is an error",
			"echo "Success: this is a success",
			"echo "This will not show without verbose mode"
		],
		...
	}
```

*What you should NOT do*:
Break the json file, for example by putting double quotes without escape char:
```
	...
		"echo \"Correct command\"",
		"echo "This will beak the json"",
	...
```

You also should NOT put a command on multiple lines (like when using "if").
```
	...
		"if [ \"$git_user\" != \"\" ]; then",
		"echo \"This will not work\"",
		"fi",
	...
```

### More complex commands

```
	...
	"actions": {
		"my-action": [
			"echo "Warning: next command has options",
			{
				exec: "ls",
				onError: "Command failed horribly"
			}
		],
		...
	}
```

- exec: the command to execute or the action to add here
- echoOnError: show on console on error
- echoOnSuccess: show on console on success
- echoBefore: show on console before the execution of the command

To fix: as the BASH shell is in buffered mode, in some case the stderr and stdout are mixed and error can show before some echo. A solution is to wait 1ms after every command, which is not very clean so we might consider something else.


### Calling an action

An action of your script is a set of shell commands (run program or function with parameters) or some calls to other actions.

A call to an action always begins with ":". So, in the command string,

```
	...
	"actions": {
		"my-action": [
			"ls -l",
			":deploy-with-git"
		],
		...
	}
```
This is an action called "my-action" that has 2 commands. When it runs, it executes "ls -l" on local machine and is calling "deploy-with-git" action. The "deploy-with-git" action can call other actions too.

If you want to see all the chain of actions, just call "captn explain example:my-action".


## Shell functions

Yep, there are shell functions.

### captn_ask

There is a common function to ask the user an information.
The response is stored on the "response" global variable.

```
	captn_ask "How old are you"
	echo "Success: your response is $response"
```

this will output :
```
	How old are you?  <-- in blue
	22
	Success: your response is 22  <-- in green
```

You can also put a default value if user response is empty (only types enter)
```
	captn_ask "Are you a troll" "no"
	echo "$response"
```
This will store "no" in the reponse if the user just hit enter

You can also ask the user if he wants to continue based on some informations. To do that, you can simply call the function "captn_ask_continue".
```
	captn_ask_continue "no"
```	


## Changelog

### V0.1.1
- Tweak deploy with git
- Fix: clean action doe not delete all the files
- Deleting unused script variable git_dir
- Adding the "echoBefore" command option
- Adding continue on error command option
- Adding "echoOnError" and "echoOnSuccess"
- Fix captn init
- Fix output in stdout sometimes does not render when exiting
- Disable log for init

### V0.1 First version
- Run scripts and do stuff

