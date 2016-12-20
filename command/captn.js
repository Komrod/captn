
var sd = require('node-screwdriver');

function captn() {
	
	this.dirRoot = process.cwd()+'/';
	this.configFile = this.dirRoot+'captn.json';
	this.hasError = false;
	this.isReady = false;
	this.configData = {};
	this.scriptData = {};

	try {
		this.configData = require(this.configFile);
	} catch (e) {
		this.hasError = true;
		throw 'Could not open "'+this.configFile+'" file. Your directory is not a captn directory';
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
			"path": "./script/"
		},
		"log": {
			"path": "./log/"
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
			"path": "./script/"
		},
		"log": {
			"path": "./log/"
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
}

/**********************************************************************
 * Script
 *********************************************************************/

captn.prototype.getScriptFile = function(scriptName) {
	return this.configData.script.path+'/'+scriptName+'.json';
};

captn.prototype.getScriptDir = function(scriptName) {
	return this.configData.script.path+'/'+scriptName+'/';
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
		result.messages.push({message: 'Could not find script "'+scriptFile+'"', type: 'error'});
		result.messages.push({message: e+'', type: 'error'});
		result.success = false;
		this.isReady = false;
		this.hasError = true;
		return result;
	}

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

captn.prototype.run = function() {
	var result = this.newResult();

	if (this.hasError) {
		result.success = false;
		return result;
	}

	if (!this.isReady) {
		result.messages.push({message: 'captn is not ready to run', type: 'error'});
		result.success = false;
		this.hasError = true;
		return result;
	}

	if (!this.scriptData) {
		result.messages.push({message: 'script data is empty', type: 'error'});
		result.success = false;
		this.hasError = true;
		return result;
	}

	try {
		// sd.mkdirpSync('')
	} catch (e) {
		result.messages.push({message: 'Could not open directory "'+dir+'"', type: 'error'});
		result.messages.push({message: e+'', type: 'error'});
		result.success = false;
		return result;
	}

	return result;
};



/**********************************************************************
 * Client
 *********************************************************************/





module.exports = new captn();


