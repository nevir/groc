require('coffee-script')
var fs   = require('fs')
var path = require ('path')

module.exports = require('autorequire')('./lib', 'Classical', {
  specialCaseModuleNames: {
    cli:         'CLI',
    cli_helpers: 'CLIHelpers',
    languages:   'LANGUAGES',
    underscore:  '_'
  },
  extraGlobalModules: [
    'coffee-script', 'colors', 'fs-tools', 'glob', 'groc', 'jade', 'optimist', 'showdown', 'spate', 'uglify-js', 'underscore'
  ]
})

module.exports.PACKAGE_INFO = JSON.parse(fs.readFileSync(path.join(__dirname, 'package.json')))
