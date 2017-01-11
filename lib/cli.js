
var sd = require('node-screwdriver');


function captn_cli() {
	this.log_write_enabled = true;
	this.log_enabled = true;
}


captn_cli.prototype.writeLog = function(message, type) {
	if (!this.log_write_enabled) {
		return false;
	}

	var file = this.getLogFile();
	if (!file) {
		this.error('Could not get log file name', false);
		this.error('Aborting on error', false);
		process.exit(1);
	}

	var dir = sd.getDir(file);
	if (!sd.dirExists(dir)) {
		sd.mkdirpSync(dir);
		if (!sd.dirExists(dir)) {
			this.error('Log directory "'+dir+'" does not exist', false);
			this.error('Aborting on error', false);
			process.exit(1);
		}
	}
	require('fs').appendFileSync(file, sd.getDateTime()+'	'+type+'	'+message.replace(/[\u001b\u009b][[()#;?]*(?:[0-9]{1,4}(?:;[0-9]{0,4})*)?[0-9A-ORZcf-nqry=><]/g, '')+"\n");
};


captn_cli.prototype.getLogFile = function() {
	if (!this.captn || !this.captn.configData || !this.captn.configData.log || this.captn.configData.log.path == '') {
		this.error('Log directory is not configured', false);
		this.error('Aborting on error', false);
		return false;
	}

/*
    var date = new Date();
    var year = date.getFullYear();
    var month = date.getMonth() + 1;
    month = (month < 10 ? "0" : "") + month;
    var day  = date.getDate();
    day = (day < 10 ? "0" : "") + day;
*/
    return this.captn.dirRoot + this.captn.configData.log.path + "captn.log";
};


/**
 * Force colors in the console using Chalk
 */

captn_cli.prototype.error = function(message, writeLog) {
	if (sd.isUndefined(writeLog)) writeLog = true;
	if (writeLog) {
		this.writeLog(message, 'ERROR');
	}
	if (!this.log_enabled) {
		return false;
	}
	const chalk = require('chalk');
	console.log(chalk.styles.red.open + message + chalk.styles.red.close);
};


captn_cli.prototype.warning = function(message) {
	if (!this.log_enabled) {
		return false;
	}
	this.writeLog(message, 'WARNING');
	const chalk = require('chalk');
	console.log(chalk.styles.yellow.open + message + chalk.styles.yellow.close);
};


captn_cli.prototype.log = function(message, force) {
	this.writeLog(message, 'LOG');
	if (!this.log_enabled) {
		return false;
	}
	if (this.program && this.program.verbose || force) {
		const chalk = require('chalk');
		console.log(chalk.styles.gray.open + message + chalk.styles.gray.close);
	}
};


captn_cli.prototype.info = function(message, force) {
	this.writeLog(message, 'INFO');
	if (!this.log_enabled) {
		return false;
	}
	if (this.program && this.program.verbose || force) {
		const chalk = require('chalk');
		console.log(chalk.styles.cyan.open + message + chalk.styles.cyan.close);
	}
};


captn_cli.prototype.result = function(message) {
	this.writeLog(message, 'RESULT');
	if (!this.log_enabled) {
		return false;
	}
	const chalk = require('chalk');
	console.log(chalk.styles.white.open + message + chalk.styles.white.close);
};


captn_cli.prototype.success = function(message) {
	this.writeLog(message, 'SUCCESS');
	if (!this.log_enabled) {
		return false;
	}
	const chalk = require('chalk');
	console.log(chalk.styles.green.open + message + chalk.styles.green.close);
};


captn_cli.prototype.act = function(result, canExit) {

	if (sd.isUndefined(canExit)) canExit = true;

	if (!result) {
		error('Result does not match an object. Aborting');
		process.exit(1);
	}

	if (result && result.messages && sd.isArray(result.messages)) {
		for (var t=0; t<result.messages.length; t++) {
			if (result.messages[t].type == 'error') {
				this.error(result.messages[t].message);
			} else if (result.messages[t].type == 'warning') {
				this.warning(result.messages[t].message);
			} else if (result.messages[t].type == 'info') {
				this.info(result.messages[t].message);
			} else if (result.messages[t].type == 'result') {
				this.result(result.messages[t].message);
			} else if (result.messages[t].type == 'success') {
				this.success(result.messages[t].message);
			} else {
				this.log(result.messages[t].message);
			}
		}
	}

	if (!result.success && canExit) {
		this.error('Aborting on error');
		process.exit(1);
	}
};

captn_cli.prototype.version = function() {
	const chalk = require('chalk');
	this.log(chalk.styles.green.open + 'captn' + chalk.styles.green.close 
		+ chalk.styles.cyan.open + ' v'+this.program._version + chalk.styles.cyan.close 
		+ ' - '+sd.getDateTime(), true);
	if (this.captn && this.captn.configData && this.captn.configData.mode) {
		cli.log('Running in '+this.captn.configData.mode+' mode');
	}

}

captn_cli.prototype.run = function() {

	try {
		this.program = require('commander');
	} catch (e) {
		this.error(e+'');
		this.error('An error occured. Aborting');
		process.exit(1);
	}

	this.program.version('0.1.0');
	var cli = this;


	this.program
		.arguments('<command> [argument:action]')
		.option("-v, --verbose", "Verbose mode")
		.option("-f, --force", "Force mode")
		.action(function(command, argument, options) {
			command = command || '';
			
			if (command != 'init') {
				cli.captn = require('./captn.js');
			} else if (command == 'init') {
				cli.log_write_enabled = false;
			}

			cli.program.version('0.1.0');
			cli.version();

			var action = '';
			if (sd.contains(argument, ':')) {
				var arr = argument.split(':');
				if (arr.length != 2 || sd.trim(arr[0]) == '' || sd.trim(arr[1]) == '') {
					cli.error('Invalid script or action "'+command+'"');
					cli.info('Proper command: captn run <scriptName>');
					cli.info('List of scripts: captn list');
					process.exit(1);
				}
				argument = arr[0];
				action = arr[1];
			}

			if (command == 'init') {
				cli.initDir();
				process.exit(0);
			}

			if (command == 'list') {
				cli.act(cli.captn.getScriptList());
				process.exit(0);
			}

			if (command == 'info') {
				if (!argument) {
					cli.error('No script specified');
					cli.info('Proper command: captn info <scriptName>');
					cli.info('List of scripts: captn list');
					process.exit(1);
				}
				cli.result('Path: '+cli.captn.getScriptFile(argument));
				if (!sd.fileExists(cli.captn.getScriptFile(argument))) {
					cli.error('Script file does not exist');
					process.exit(1);
				}
				cli.act(cli.captn.loadScript(argument));
				cli.result('Description: '+(cli.captn.scriptData.description || ''));
				cli.result('SSH host: '+(cli.captn.scriptData.sshHost || 'none'));
				cli.result('SSH port: '+(cli.captn.scriptData.sshPort || 'none')
					+', default '+cli.captn.getDefaultSshPort());
				cli.result('SSH user: '+(cli.captn.scriptData.sshUser || 'none')
					+', default '+cli.captn.getDefaultUsername());
				cli.result('GIT user: '+(cli.captn.scriptData.gitUser || 'none')
					+', default '+cli.captn.getDefaultUsername());
				cli.result('GIT branch: '+cli.captn.scriptData.gitBranch);
				cli.result('Target directory: '+cli.captn.scriptData.targetDir);
				process.exit(0);
			}

			if (command == 'explain') {
				if (!argument) {
					cli.error('No script specified');
					cli.info('Proper command: captn explain <scriptName:action>');
					cli.info('List of scripts: captn list');
					process.exit(1);
				}

				cli.act(cli.captn.loadScript(argument));

				cli.log('Explain script and action');
				console.log('');
				cli.captn.explainScript(action, handleLog, handleError, handleExit, function(message) { handleResult(message, true)});
				process.exit(0);
			}

			// run
			if (command == 'run') {
				if (!argument) {
					cli.error('No script specified');
					cli.info('Proper command: captn run <scriptName>');
					cli.info('List of scripts: captn list');
					process.exit(1);
				}
				
				cli.act(cli.captn.loadScript(argument));



				cli.result('Start script');
				cli.log('Press [ctrl-c] at any time to quit');
				cli.captn.runScript(action, handleLog, handleError, handleExit, handleResult);
				process.exit(0);
			}

			cli.error('Unrecognized command');
			if (cli.program && cli.program.verbose) {
				cli.program.outputHelp();
			}
			process.exit(1);


			function handleExit(code) {
				if (code == 0) {
					cli.log('Script exit with no error. Exit code '+code);
					process.exit(0);
				}

				cli.error('Script exit with error. Exit code '+code);
				process.exit(code);
			}

			function handleLog(message) {
				var res = message.split("\n");
				if (res.length > 1) {
					for (var t=0; t<res.length; t++) {
						handleLog(res[t]);
					}
					return;
				}
				if (sd.startsWith(sd.trim(message), 'Success:')) {
					cli.success(message);
				} else if (sd.startsWith(sd.trim(message), 'Warning:')){
					cli.warning(message);
				} else if (sd.startsWith(sd.trim(message), 'Error:')){
					cli.error(message);
				} else if (sd.startsWith(sd.trim(message), 'Info:')){
					cli.info(message);
				} else if (sd.endsWith(sd.trim(message), '?')){
					cli.info(message, true);
				} else {
					cli.log(message);
				}
			}

			function handleError(message) {
				var res = message.split("\n");
				if (res.length > 1) {
					for (var t=0; t<res.length; t++) {
						handleError(res[t]);
					}
					return;
				}
				cli.error(message);
			}

			function handleResult(message, force) {
				force = force || false;
				var res = message.split("\n");
				if (res.length > 1) {
					for (var t=0; t<res.length; t++) {
						handleResult(res[t], force);
					}
					return;
				}
				if (sd.startsWith(sd.trim(message), 'Success:')) {
					cli.success(message);
				} else if (sd.startsWith(sd.trim(message), 'Warning:')) {
					cli.warning(message);
				} else if (sd.startsWith(sd.trim(message), 'Error:')) {
					cli.error(message);
				} else if (sd.startsWith(sd.trim(message), 'Info:')) {
					cli.info(message);
				} else if (sd.endsWith(sd.trim(message), '?')) {
					cli.info(message, true);
				} else {
					if (cli.program.verbose || force) {
						cli.result(message);
					} else {
						cli.log(message);
					}
				}
			}			
			
		})
		.parse(process.argv);

	this.version();
	this.error('No command to execute');
	if (this.program && this.program.verbose) {
		this.program.outputHelp();
	}
	process.exit(1);
};


captn_cli.prototype.initDir = function() {
	
	var destination = require('path').resolve(process.cwd()+'/');
	var source = require('path').resolve(__dirname+'/../example/');

	console.log('Source is "'+source+'"');
	console.log('Destination is "'+destination+'"');

	var ncp = require('ncp').ncp;
	var quit = false;
	var cli = this;
	var options = {
		clobber: false
	};
	ncp.limit = 16;
	
	ncp(source, destination, options, function (err) {
		if (err) {
			cli.error(err);
			quit = true;
			return false;
		}
		cli.success('Directory initiated');
		quit = true;
		return true;
	});

	while (!quit) {
	   require('deasync').sleep(10);
	}

};


var cli = new captn_cli();
cli.run();

