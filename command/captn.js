
var sd = require('node-screwdriver');

function captn() {
	
	this.configFile = '../captn.json';
	this.hasError = false;
	this.isReady = false;
	this.configData = {};
	this.scriptData = {};

	try {
		this.configData = require(this.configFile);
	} catch (e) {
		this.hasError = true;
		throw 'Could not open "'+this.configFile+'" file';
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


/**********************************************************************
 * Script
 *********************************************************************/

captn.prototype.getScriptFile = function(scriptName) {
	return this.configData.script.path+'/'+scriptName+'.json';
};

captn.prototype.getScriptDir = function(scriptName) {
	return this.configData.script.path+'/'+scriptName+'/';
};

captn.prototype.createScriptDir = function(scriptName) {
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
		this.scriptData = require('../'+scriptFile);
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
		result.messages.push({message: 'List (total '+result.list.length+'):', type: 'info'});
		for (var t=0; t<result.list.length; t++) {
			result.messages.push({message: '- '+sd.getNoExtension(files[t]), type: 'info'});
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


