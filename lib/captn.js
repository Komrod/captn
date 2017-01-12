

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

captn.prototype.explainScript = function(action, onLog, onError, onExit, onResult) {

	action = action || 'default';

	// check error state
	if (this.hasError) {
		onError('Could not explain script. Captn is in an error state');
		onExit(1);
		return false;
	}

	// check if captn is ready
	if (!this.isReady) {
		onError('Could not explain script. Captn is not ready to run');
		onExit(1);
		return false;
	}

	// check if script data is loaded
	if (!this.scriptData) {
		onError('Could not explain script. Script data is empty');
		onExit(1);
		return false;
	}

	// check is there are commands in script data
	if (!this.scriptData.actions) {
		onError('No actions to explain');
		onExit(1);
		return false;
	}

	// check action
	if (!sd.isArray(this.scriptData.actions[action])) {
		onError('Action "'+action+'" is unknown');
		onExit(1);
		return false;
	}

	if (!this.buildScript(action, onLog, onError)) {
		onError('Could not build script');
		onExit(1);
		return false;
	}
	try {
		// explain action 
		onResult('Action "'+action+'"');
		this.explainAction(action, 1, onResult);
		
	} catch (e) {
		onError(e+'');
		onExit(1);
		return false;
	}

	onExit(0);
	return false;
};

captn.prototype.explainAction = function(action, level, onResult) {
	var space = "";
	for (var t=0; t<level-1; t++) space += " ";
	if (level != 0) space += "-";
	space += " ";

	// check action
//console.log('action = '+action);
//console.log(this.scriptData.actions[action]);
	if (!sd.isArray(this.scriptData.actions[action])) {
		onResult(space+'(unknown)');
		return false;
	}

	for (var t=0; t<this.scriptData.actions[action].length; t++) {
		var command = this.scriptData.actions[action][t];
		if (sd.isString(command)) command = {exec: command};

		if (sd.startsWith(command.exec, ':')) {
			onResult(space+'Action "'+command.exec.substring(1)+'"');
			this.explainAction(command.exec.substring(1), level+2, onResult);
		} else if (sd.startsWith(sd.trim(command.exec), '#')) {
			onResult(space+command.exec);
			if (this.scriptData.actions[action].length == 1) {
				onResult(space+'(no other command or action)');
			}
		}
	}
	if (this.scriptData.actions[action].length == 0) {
		onResult(space+'(no command or action)');
	}
	return true;
};


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

	if (!this.buildScript(action, onLog, onError)) {
		onError('Could not build script');
		onExit(1);
		return false;
	}

	if (this.scriptData.script_dir == "") {
		onError('Script cache directory name is empty');
		onExit(1);
		return false;
	}

	if (!sd.dirExists(this.scriptData.script_dir)) {
		require('fs').mkdirSync(this.scriptData.script_dir);
		if (!sd.dirExists(this.scriptData.script_dir)) {
			onError('Directory "'+this.scriptData.script_dir+'" could not be created');
			onExit(1);
			return false;
		}
	}

	try {
		onLog('Running script');

		var spawn = require('child_process').spawn,
		    shell = spawn(this.configData.script.shell || 'bash', [this.scriptData.script_sh]),
		    quit = false;

		if (!shell) {
			onError("Could not open shell. Aborting");
			onExit(1);
		}
		
		process.stdin.pipe(shell.stdin);

/*		shell.stdio.on('data', function (data) {
		  onResult(sd.trim(data.toString()));
		});*/

		shell.stdout.on('data', function (data) {
			onResult(sd.trim(data.toString()));
		});

		shell.stderr.on('data', function (data) {
			onError(sd.trim(data.toString()));
		});

		shell.on('exit', function (code) {
			// actually waits to complete result and error log
			setTimeout(function() {
				onExit(code);
				quit = true;
			}, 100);
		});

		while (!quit) {
		   require('deasync').sleep(10);
		}

	} catch (e) {
		onError(e+'');
		onExit(1);
		return false;
	}

	onExit(0);
	return false;
};


captn.prototype.buildScript = function(action, onLog, onError) {

	// delete previous script
	this.scriptData.script_sh = require('path').resolve(this.configData.script.path+this.scriptName+'.sh');
	if (sd.fileExists(this.scriptData.script_sh)) {
		onLog('Deleting previous script file "'+this.scriptData.script_sh+'"');
		require('fs').unlinkSync(this.scriptData.script_sh);
		if (sd.fileExists(this.scriptData.script_sh)) {
			onError('File "'+this.scriptData.script_sh+'" cannot be deleted');
			return false;
		}
	}

	var content = "#!/bin/bash\n\n";
	content += "#######################################\n";
	content += "# Captn - shell script\n";
	content += "#######################################\n";
	content += "# Name: "+this.scriptData.script_name+"\n";
	content += "# Description: "+this.scriptData.script_description+"\n";
	content += "# Date: "+this.scriptData.script_date+"\n";
	content += "# Local host: "+this.scriptData.script_local+"\n";
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

 	content += this.scriptFunctions;


	try {
		content += this.getAction(action, onLog, onError, function() {}, onLog);

		onLog('Writting script in file "'+this.scriptData.script_sh+'"');
		require('fs').writeFileSync(this.scriptData.script_sh, content);
	} catch (e) {
		onError(e+'');
		return false;
	}

	return true;
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

	if (command.echoBefore) {
		content += "(>&1 echo  \""+command.echoBefore+"\")\n";
	}
	
	// Sleep here to prevent stdout stderr unsynch
	content += "sleep 0.001\n";

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
	if (command.echoOnError) {
		content += "    (>&2 echo  \""+command.echoOnError+"\")\n";
	}
	if (!command.continueOnError) {
		content += "    (>&2 echo \"Command failed. Aborting\")\n";
		content += "    exit 1;\n";
	}
	content += "    :\n";
	content += "fi\n";
	if (command.echoOnSuccess) {
		content += "echo  \""+command.echoOnSuccess+"\"\n";
	}
	content += "\n";

	return content;
};




/*
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
*/

/**********************************************************************
 * Client
 *********************************************************************/





module.exports = new captn();


