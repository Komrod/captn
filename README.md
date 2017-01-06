# captn

Easy web server deployment

This is a prototype.


## Requires

Captn will run on Linux and Windows as long as you have those things:
- Bash shell commands on client and server
- Node
- GIT (optional)
- Remote server with SSH access
- Installed SSH keys to autoconnect

It's pretty standard for Linux. On windows, you can install GIT bash that will provide GIT commands and Bash shell when you launch a Bash console.


There is many ways to configure captn and deploy your project on the server.

Regular features include:
- Verify commit id with GIT server on client
- Ask for commit id to deploy
- Clone and verify site on client machine
- archive on remote server
- Deploy on remote from the GIT server
- Build a package on client machine
- Deploy package on remote server
- Log everything
- Stop script on critical error


Different approach on how to deploy from a developper client machine :

```
Cilent		---	Deploy ---> 	Remote server
Run captn						Website

Client		--- Connect -->		Captn server	--- Deploy --->		Remote server
Run SSH							Run captn							Website
```
The GIT and SSH can be configured in
You can also configure your script to ask for a GIT login or SSH login if you want.


## Quick start

### Install

Install with npm:

```
	npm install -g captn
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

### Share the project by GIT

Your captn project with your scripts


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
	captn run <script>
	captn run <script>:<action>
```

If you omit the action, the default action is executed

### Explain

```
	captn explain <script>
	captn explain <script>:<action>
```

This command take the first comment of every actions that is launched by the selected script action. Execute "captn explain <script>" to see the explanation of the default action. Execute "captn explain <script>:<action>" to see the explanation of a particular action.

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

*What you should not do*:
Break the json file, for example by putting double quotes without escape char:
```
	...
		"echo \"Correct command\"",
		"echo "This will beak the json"",
	...
```

You alsa shoulnd put a command on multiple lines (like when using "if").
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

- onError: show on console on error
- onSuccess: show on console on success
- 


### Ask the captain

There is a common function to ask the user an information.
The response is stored on the $response global variable.

```
	captn_ask "How old are you"
	echo "Success: your response is $response"
```
this will output :
```
	How old are you?
	22
	Your response is 22
```
You can also put a default value if the
```
	captn_ask "Are you a troll" "no"
	echo "$response"
```
This will store "no" in the reponse if the user just hit enter

You can also ask the user if he wants to continue based on some informations. To do that, you can simply call the function "captn_ask_continue".
```
	captn_ask_continue "no"
```	


### Calling an action

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




## Actions

### deploy-with-git

This action will:
- 



## Functions

## Changelog

### V0.1 First version
- Run scripts

