
var sd = require('node-screwdriver');

function captn() {
	
	this.configFile = './captn.json';
	this.hasError = false;
	this.isReady = false;
	this.configData = {};
	this.scriptData = {};

	try {
		this.configData = require(this.configFile);
	} catch (e) {
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

	result.messages.push({message: 'Loading script "'+scriptFile+'"', type: 'log'});

	this.scriptName = scriptName;
	this.isReady = false;
	
	var scriptFile = this.getScriptFile(scriptName);
	try {
		this.scriptData = require(scriptFile);
	} catch (e) {
		result.messages.push({message: 'Could not find script "'+scriptFile+'"', type: 'error'});
		result.success = false,
		this.isReady = false;
		return result;
	}

	result.messages.push({message: 'Successfull', type: 'log'});
	this.isReady = true;
	return result;
};


/**********************************************************************
 * Server
 *********************************************************************/




/**********************************************************************
 * Client
 *********************************************************************/





module.exports = new captn();


