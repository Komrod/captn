

var sd = require('node-screwdriver');


function captn() {
	
	this.dirRoot = process.cwd()+'/';
	this.configFile = this.dirRoot+'captn.json';
	this.hasError = false;
	this.isReady = false;
	this.configData = {};
	this.scriptName = '';
	this.scriptData = {};
	this.scriptFunctions = '';

	try {
		this.configData = require(this.configFile);
	} catch (e) {
		this.hasError = true;
		throw 'Could not open "'+this.configFile+'" file. Your directory is not a captn directory';
	}

	if (!sd.endsWith(this.configData.script.path, '/')) {
		this.configData.script.path += '/';
	}
	if (!sd.endsWith(this.configData.log.path, '/')) {
		this.configData.log.path += '/';
	}

	this.scriptFunctions = '';
	if (this.configData.script.include) {
		for (var t=0; t<this.configData.script.include.length; t++) {
			var file = this.dirRoot+this.configData.script.include[t];
			if (sd.fileExists(file)) {
				this.scriptFunctions += "# File "+file+"\n\n"+require('fs').readFileSync(file)+"\n\n\n";
			} else {
				this.hasError = true;
				throw 'Could not open "'+file+'" file as function shell script';
			}
		}
	}

	this.scriptExtend = {};
	if (this.configData.script.extend) {
		var file = this.dirRoot+this.configData.script.extend;
		if (sd.fileExists(file)) {
			this.scriptExtend = require(file);
		} else {
			this.hasError = true;
			throw 'Could not open "'+file+'" file as extend script file';
		}
	}

};

/*
captn.prototype.initClientDir = function() {
	
	var result = this.newResult();
	result.messages.push({message: 'Initializing directory in client mode', type: 'log'});
	
	this.createDir(this.dirRoot+'log/', result);
	this.createDir(this.dirRoot+'script/', result);

	var content = JSON.stringify({
		"mode": "client",
		"script": {
			"path": "script/"
		},
		"log": {
			"path": "log/"
		}
	});
	this.createFile(this.dirRoot+'captn.json', content, result);

	var content = "*.log\nnpm-debug.log*\nnode_modules\n.npm\n*.crt\n*.key\n";
	this.createFile(this.dirRoot+'captn.json', content, result);

	return result;
};


captn.prototype.initServerDir = function() {
	
	var result = this.newResult();
	result.messages.push({message: 'Initializing directory in server mode', type: 'log'});
	
	this.createDir(this.dirRoot+'log/', result);
	this.createDir(this.dirRoot+'script/', result);

	var content = JSON.stringify({
		"mode": "server",
		"script": {
			"path": "script/"
		},
		"log": {
			"path": "log/"
		}
	});
	this.createFile(this.dirRoot+'captn.json', content, result);

	var content = "*.log\nnpm-debug.log*\nnode_modules\n.npm\n*.crt\n*.key\n";
	this.createFile(this.dirRoot+'captn.json', content, result);

	return result;
};
*/

captn.prototype.createFile = function(file, content, result) {
	if (!sd.fileExists(file)) {
		result.messages.push({message: 'Creating the file "'+file+'"', type: 'log'});
		try {
			require('fs').writeFileSync(file, content);
		} catch (e) {
			result.messages.push({message: 'Could not write file "'+file+'"', type: 'error'});
			result.messages.push({message: (e+''), type: 'error'});
		}
	} else {
		result.messages.push({message: 'The file "'+file+'" already exists', type: 'log'});
	}
};


captn.prototype.createDir = function(dir, result) {
	if (!sd.dirExists(dir)) {
		result.messages.push({message: 'Creating the directory "'+dir+'"', type: 'log'});
		sd.mkdirpSync(dir);
		if (!sd.dirExists(dir)) {
			result.messages.push({message: 'Could not create directory "'+dir+'"', type: 'error'});
		}
	} else {
		result.messages.push({message: 'The directory "'+dir+'" already exists', type: 'log'});
	}
};


/**********************************************************************
 * Result
 *********************************************************************/


captn.prototype.newResult = function() {
	return {
		messages: [],
		success: true
	}
};


captn.prototype.getDefaultUsername = function() {
	var path = require('path');
	return process.env['USERPROFILE'].split(path.sep)[2] || '';
};

captn.prototype.getDefaultSshPort = function() {
	return 22;
};




/**********************************************************************
 * Script
 *********************************************************************/

captn.prototype.getScriptFile = function(scriptName) {
	return this.configData.script.path+scriptName+'.json';
};

captn.prototype.getScriptDir = function(scriptName) {
	return this.configData.script.path+scriptName+'/';
};


captn.prototype.loadScript = function(scriptName) {
	var result = this.newResult();

	if (this.hasError) {
		result.success = false;
		return result;
	}

	result.messages.push({message: 'Loading script "'+scriptName+'"', type: 'log'});

	this.scriptName = scriptName;
	this.isReady = false;

	// copy scriptExtend in scriptData
	this.scriptData = this.scriptExtend;

	// get script file content
	var scriptFile = this.getScriptFile(scriptName);
	try {
		var newScript = require(this.dirRoot+scriptFile);
	} catch (e) {
		result.messages.push({message: 'Could not load script "'+scriptFile+'"', type: 'error'});
		result.messages.push({message: e+'', type: 'error'});
		result.success = false;
		this.isReady = false;
		this.hasError = true;
		this.scriptName = '';
		return result;
	}

	// copy script in 
	for (var name in newScript) {
		if (sd.isObject(newScript[name])) {
			if (sd.isUndefined(this.scriptData[name])) {
				this.scriptData[name] = {};
			}
			for (var actionName in newScript[name]) {
				this.scriptData[name][actionName] = newScript[name][actionName];
			}
		} else {
			this.scriptData[name] = newScript[name];
		}
	}
//console.log(this.scriptData); process.exit();

	this.scriptName = scriptName;
	this.isReady = true;

	this.scriptData.script_name = this.scriptName;
	this.scriptData.script_file = scriptFile;
	this.scriptData.script_json = require('path').resolve(this.configData.script.path+this.scriptName+'.json');
	this.scriptData.script_dir = require('path').resolve(this.configData.script.path+this.scriptName+'/');
	this.scriptData.script_sh = require('path').resolve(this.configData.script.path+this.scriptName+'.sh');
	this.scriptData.script_action = '';
	this.scriptData.script_date = sd.getDateTime();
	this.scriptData.script_local = require("os").hostname();
	this.scriptData.script_true_values = this.configData.script.true_values.join(' ');

	this.scriptData.git_commit_list = "";
	this.scriptData.git_commit_head = "";
	
	return result;
};


captn.prototype.getScriptList = function(scriptName) {
	var result = this.newResult();

	if (this.hasError) {
		result.success = false;
		return result;
	}

	var dir = this.configData.script.path;
	result.messages.push({message: 'Loading script list from "'+dir+'"', type: 'log'});

	try {
		var files = require('fs').readdirSync(dir);
		result.list = [];
		for (var t=0; t<files.length; t++) {
			if (sd.getExtension(files[t]).toLowerCase() == 'json') {
				result.list.push(sd.getNoExtension(files[t]));
			}
		}
		result.messages.push({message: 'List (total '+result.list.length+'):', type: 'log'});
		for (var t=0; t<result.list.length; t++) {
			result.messages.push({message: '- '+sd.getNoExtension(files[t]), type: 'result'});
		}
		if (result.list.length == 0) {
			result.messages.push({message: '(none)', type: 'result'});
		}
	} catch (e) {
		result.messages.push({message: 'Could not open directory "'+dir+'"', type: 'error'});
		result.messages.push({message: e+'', type: 'error'});
		result.success = false;
		return result;
	}

	return result;
};


/**********************************************************************
 * Server
 *********************************************************************/

captn.prototype.runScript = function(action, onLog, onError, onExit, onResult) {

	action = action || 'default';
	this.scriptData.script_action = action;

	// check error state
	if (this.hasError) {
		onError('Could not run script. Captn is in an error state');
		onExit(1);
		return false;
	}

	// check if captn is ready
	if (!this.isReady) {
		onError('Could not run script. Captn is not ready to run');
		onExit(1);
		return false;
	}

	// check if script data is loaded
	if (!this.scriptData) {
		onError('Could not run script. Script data is empty');
		onExit(1);
		return false;
	}

	// check is there are commands in script data
	if (!this.scriptData.actions) {
		onError('No actions to run');
		onExit(1);
		return false;
	}

	// check action
	if (!sd.isArray(this.scriptData.actions[action])) {
		onError('Action "'+action+'" is unknown');
		onExit(1);
		return false;
	}


	// delete previous script
	this.scriptData.script_sh = require('path').resolve(this.configData.script.path+this.scriptName+'.sh');
	if (sd.fileExists(this.scriptData.script_sh)) {
		onLog('Deleting previous script file "'+this.scriptData.script_sh+'"');
		require('fs').unlinkSync(this.scriptData.script_sh);
		if (sd.fileExists(this.scriptData.script_sh)) {
			onError('File "'+this.scriptData.script_sh+'" cannot be deleted');
			onExit(1);
			return false;
		}
	}


	var content = "#!/bin/bash\n\n";
	content += "#######################################\n";
	content += "# Captn - deploy script\n";
	content += "#######################################\n";
	content += "# Name: "+this.scriptData.script_name+"\n";
	content += "# Description: "+this.scriptData.script_description+"\n";
	content += "# Date: "+this.scriptData.script_date+"\n";
	content += "# Local host: "+this.scriptData.script_local+"\n";
	content += "# SSH user: "+this.scriptData.ssh_user+"\n";
	content += "# SSH server: "+this.scriptData.ssh_host+":"+this.scriptData.ssh_port+"\n";
	content += "# GIT user: "+this.scriptData.git_user+"\n";
	content += "# GIT repository: "+this.scriptData.git_repo+"\n";
	content += "# Target dir: "+this.scriptData.git_dir+"\n";
	content += "#######################################\n";
	content += "\n";
	content += "\n";

	content += "# Variables\n";
	content += "\n";
	for(var name in this.scriptData) {
		if (sd.isArray(this.scriptData[name])) {
			content += name+"=\""+this.scriptData[name].join(' ')+"\"\n";
		} else if (sd.isObject(this.scriptData[name])) {
			// do nothing
		} else {
			content += name+"=\""+this.scriptData[name]+"\"\n";
		}
	}
	content += "\n";
	content += "\n";


/*

script_json: absolute path for the json file of the script
script_sh: absolute path for the sh file of the script
script_name: name of the script
script_target: target directory of the site to deploy

git_user:
git_dir:
git_branch_from:
git_branch_to:

ssh_host:
ssh_port:
ssh_user:

skip_check: value 1 if you want to skip the captn_git_check
skip_patch: value 1 if you want to skip the captn_git_patch and captn_apply
skip_deploy: value 1 if you want to skip the captn_deploy

captn_dir: root directory of captn
captn_version: version of captn


Functions:
captn_clean: function to clean all directories
captn_check: function to check if git branch is ready
captn_patch: function to get the patch between the 2 branches
captn_deploy: function to apply patch to 

 */

 	content += this.scriptFunctions;


	try {
		content += this.getAction(action, onLog, onError, onExit, onResult);

		onLog('Writting script in file "'+this.scriptData.script_sh+'"');
		require('fs').writeFileSync(this.scriptData.script_sh, content);

		onLog('Running script');

		var spawn = require('child_process').spawn,
		    shell = spawn(this.configData.script.shell || 'bash', [this.scriptData.script_sh]),
		    quit = false;

		if (!shell) {
			onError("Could not open shell. Aborting");
			onExit(1);
		}
		
		process.stdin.pipe(shell.stdin);

		shell.stdout.on('data', function (data) {
		  onResult(sd.trim(data.toString()));
		});

		shell.stderr.on('data', function (data) {
		  onError(sd.trim(data.toString()));
		});

		shell.on('exit', function (code) {
		  onExit(code);
		  quit = true;
		});

		while (!quit) {
		   require('deasync').sleep(100);
		}

	} catch (e) {
		onError(e+'');
		onExit(1);
		return false;
	}

	onExit(0);
	return false;
};


captn.prototype.getAction = function(action, onLog, onError, onExit, onResult) {
	var content = '';
	var commands = this.scriptData.actions[action];
	if (!commands) {
		onError('Action "'+action+'" is unknown');
		onExit(1);
		return false;
	}
	for (var t=0; t<commands.length; t++) {
		content += this.getCommand(commands[t], onLog, onError, onExit, onResult);
	}
	return content;
};


captn.prototype.getCommand = function(command, onLog, onError, onExit, onResult) {

	var content = "#######################################\n";
	
	if (sd.isString(command)) {
		command = {exec: command};
	}

	if (command.skip) {
		content += "# "+command.exec+"\n";
		content += "# Skip this command \n";
		content += "\n";
		return content;
	}

	if (sd.startsWith(command.exec, '#')) {
		content += command.exec+"\n";
		content += "\n";
		return content;
	}

	if (sd.startsWith(sd.trim(command.exec), ':')) {
		var action = command.exec.substr(1);
		content += "# Start action \""+action+"\"\n";
		content += "\n";
		content += this.getAction(action, onLog, onError, onExit, onResult);
		content += "\n";
		content += "# End action \""+action+"\"\n";
		content += "\n";

		return content;
	}

	content += command.exec+"\n";
	content += "if [ $? != 0 ]; then\n"
	if (command.onError) {
		content += "    (>&2 echo  \""+command.onError+"\")\n";
	} else {
		content += "    (>&2 echo \"Command failed. Aborting\")\n";
	}
	content += "    exit 1;\n";
	content += "fi\n";
	if (command.onSuccess) {
		content += "echo  \""+command.onSuccess+"\"\n";
	}
	content += "\n";

	return content;
};





captn.prototype.runCommand = function(command, result) {
	result = result || this.newResult();
	var quit = false;

	if (sd.isString(command)) {
		command = this.getCommand(command);
	} else if (sd.contains(command.exec, " ")) {
		tmp = this.getCommand(command.exec);
		command.exec = tmp.exec;
		if (tmp.params) {
			command.params = tmp.params;
		} else {
			command.params = [];
		}
	}

	if (sd.isString(command.params) && command.params != '') {
		command.params = [command.params];
	} else if (!sd.isArray(command.params)) {
		command.params = null;
	}

	if (command.skip) {
		result.messages.push({message: 'Skipping command "'+command.exec+'"', type: 'warning'});
		return result;
	}

	if (command.onStart) {
		result.messages.push({message: command.onStart, type: 'result'});
	}

	const spawn = require('child_process').spawn;
	const exec = require('child_process').exec;

	exec(this.getCommandLine(command), (error, stdout, stderr) => {
		if (!command.hideResult) {
			if (sd.trim(stdout) != '' && !command.hideResult) {
				result.messages.push({message: sd.trim(stdout), type: 'result'});
			}
		}
		if (error) {
			if (sd.trim(stderr) != '') {
				result.messages.push({message: sd.trim(stderr), type: 'error'});
			}
			result.messages.push({message: "An error occured", type: 'error'});
			quit = true;
			return;
		} else {
			if (sd.trim(stderr) != '') {
				result.messages.push({message: sd.trim(stderr), type: 'warning'});
			}
		}

		quit = true;
	});


	while (quit === false) {
		require('deasync').sleep(10);
	}

	return result;
};


/**********************************************************************
 * Client
 *********************************************************************/





module.exports = new captn();


