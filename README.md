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

It's pretty standard for Linux. On windows, you can install GIT bash that will provide GIT commands and Bash commands when you launch a Bash console.


There is many ways to configure captn and deploy your project on the server.

Regular features include:
- Verify commit id from GIT on client
- Ask for commit id to deploy
- Clone and verify site on client machine
- archive on remote server
- Deploy on remote from the GIT server
- Build a package on client machine
- Deplot package on remote server


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

### Make your own project

It is recommanded that you install globaly so you can run captn from anywhere.
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
If you configure correctly the variables inside your .json file (GIT, SSH ...), you will be able to connect automatically to the server by SSH

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

You can add 

## How to cutomize your script

### Just adding a simple command

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

### More complex commands


## Actions



## Functions

## Changelog

### V0.1 First version
- Run scripts

