
var sd = require('node-screwdriver');

function captn() {
	
	this.dirRoot = process.cwd()+'/';
	this.configFile = this.dirRoot+'captn.json';
	this.hasError = false;
	this.isReady = false;
	this.configData = {};
	this.scriptName = '';
	this.scriptData = {};

	try {
		this.configData = require(this.configFile);
	} catch (e) {
		this.hasError = true;
		throw 'Could not open "'+this.configFile+'" file. Your directory is not a captn directory';
	}

	if (this.configData.mode != 'server' && this.configData.mode != 'server') {
		this.configData.mode = 'client';
	}
	if (!sd.endsWith(this.configData.script.path, '/')) {
		this.configData.script.path += '/';
	}
	if (!sd.endsWith(this.configData.log.path, '/')) {
		this.configData.log.path += '/';
	}
};


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
	
	var scriptFile = this.getScriptFile(scriptName);
	try {
		this.scriptData = require(this.dirRoot+scriptFile);
	} catch (e) {
		result.messages.push({message: 'Could not load script "'+scriptFile+'"', type: 'error'});
		result.messages.push({message: e+'', type: 'error'});
		result.success = false;
		this.isReady = false;
		this.hasError = true;
		this.scriptName = '';
		return result;
	}

	this.scriptName = scriptName;
	this.isReady = true;
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

captn.prototype.runScript = function(onLog, onError, onExit, onResult) {

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
	if (!this.scriptData.commands || this.scriptData.commands.length == 0) {
		onError('No commands to run');
		onExit(1);
		return false;
	}

	// delete previous script
	var file = this.configData.script.path+this.scriptName+'.sh';
	if (sd.fileExists(file)) {
		onLog('Deleting previous script file "'+file+'"');
		require('fs').unlinkSync(file);
		if (sd.fileExists(file)) {
			onError('File "'+file+'" cannot be deleted');
			onExit(1);
			return false;
		}
	}


	var content = "#!/bin/bash\n\n";
	var os = require("os");
	content += "#######################################\n";
	content += "# Captn - deploy script\n";
	content += "#######################################\n";
	content += "# Date: "+sd.getDateTime()+"\n";
	content += "# Host: "+os.hostname()+"\n";
	content += "# SSH user: "+this.scriptData.sshUser+" ("+this.getDefaultUsername()+")\n";
	content += "# To server: "+this.scriptData.sshHost+"\n";
	content += "#######################################\n";
	content += "\n";
	content += "\n";

	try {
		for (t=0; t<this.scriptData.commands.length; t++) {
			content += "#######################################\n";
			content += "# Command "+(t+1)+"\n";
			if (this.scriptData.commands[t].skip) {
				content += "# "+this.getCommandLine(this.scriptData.commands[t])+"\n";
				content += "# Skip this command \n";
				content += "\n";
				continue;
			}
			content += this.getCommandLine(this.scriptData.commands[t])+"\n";
			content += "if [ $? != 0 ]; then\n"
			if (this.scriptData.commands[t].onError) {
				content += "    (>&2 echo  \""+this.scriptData.commands[t].onError+"\")\n";
			} else {
				content += "    (>&2 echo \"Command failed. Aborting.\")\n";
			}
	    	content += "    exit 1;\n";
			content += "fi\n";
			if (this.scriptData.commands[t].onSuccess) {
				content += "echo  \""+this.scriptData.commands[t].onSuccess+"\"\n";
			}
			content += "\n";
		}

		onLog('Writting script in file "'+file+'"');
		require('fs').writeFileSync(file, content);

		onLog('Running script');

		var spawn = require('child_process').spawn,
		    shell = spawn('sh', [file]),
		    quit = false;

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


captn.prototype.getCommandLine = function(command) {
	if (sd.isString(command)) {
		return command;
	}
	var line = command.exec;
	if (command.params && sd.isString(command.params)) {
		line += ' '+command.params;
	} else if (command.params && command.params.length > 0) {
		line += ' '+command.params.join(' ');
	}
	return sd.trim(line);
};


captn.prototype.getCommand = function(str) {
	var elements = str.split(' ');
	var command = {
		exec: elements[0],
	};
	elements.shift();
	if (elements.length > 0) {
		command.params = elements;
	}
	return command;
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

	/*
	if (command.params) {
	    cmd = spawn(command.exec, command.params);
	} else {
	    cmd = spawn(command.exec);
	}


	cmd.stdout.on('data', (data) => {
		if (!command.hideResult) {
			result.messages.push({message: sd.trim(data), type: 'result'});
		}
	});

	cmd.stderr.on('data', (data) => {
		result.messages.push({message: sd.trim(data), type: 'error'});
	});

	cmd.on('close', (code) => {
		result.messages.push({message: 'Command exit with code '+code, type: 'log'});
		if (code != 0 && command.onError) {
			result.messages.push({message: command.onError, type: 'error'});
		}
		if (code == 0 && command.onError) {
			result.messages.push({message: command.onSuccess, type: 'success'});
		}
		result.success = false;
		quit = true;
	});

	while (quit === false) {
		require('deasync').sleep(10);
	}

	return result;
	*/
};


/**********************************************************************
 * Client
 *********************************************************************/





module.exports = new captn();


