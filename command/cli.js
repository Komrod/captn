
var program = require('commander');
var sd = require('node-screwdriver');

//var path = require('path');
//var userName = process.env['USERPROFILE'].split(path.sep)[2];



/**
 * Force colors in the console using Chalk
 */

function error(message) {
	const chalk = require('chalk');
	console.log(chalk.styles.red.open + message + chalk.styles.red.close);
}

function warning(message) {
	const chalk = require('chalk');
	console.log(chalk.styles.yellow.open + message + chalk.styles.yellow.close);
}

function log(message) {
	console.log(message);
}

function info(message) {
	const chalk = require('chalk');
	console.log(chalk.styles.cyan.open + message + chalk.styles.cyan.close);
}

function act(result, canExit) {

	if (sd.isUndefined(canExit)) canExit = true;

	if (!result) {
		error('Result does not match an object. Aborting');
		process.exit(1);
	}

	if (!result.success && canExit) {
		error('Aborting');
		process.exit(1);

	}
}




try {
	var captn = require('./captn.js');
} catch (e) {
	error(e);
	process.exit(1);
}

program
	.version('0.1.0');

info('captn v'+program._version+' - '+sd.getDateTime());


program
	.arguments('<command> [argument]')
/*
	.option("-d, --default [defaultName]", "Set the default script")
	.option("-c, --create [createName]", "Create a script")
	.option("-g, --git [branch]", "Branch or tag to update to")
	.option("-d, --dir [dir]", "Working directory")
	.option("-u, --user [userName]", "User name, default current user")
*/
	.action(function(command, argument, options) {
//console.log('command='+command+', argument='+argument+', options=', options);		
		command = command || '';

		if (command == 'list') {
			act(captn.getScriptList());
		}

		// server
		if (command == 'run') {
			
			if (!argument) {
				error('No script specified');
				info('Proper command: captn run <scriptName>');
				info('List of scripts: captn --list');
				process.exit(1);
			}
			var scriptName = options.argument;
			act(captn.scriptLoad(scriptName));
		}

		// client
		
	})
	.parse(process.argv);


error('No command to execute');
program.outputHelp();
process.exit(1);

