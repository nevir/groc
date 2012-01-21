require('coffee-script')

module.exports = require('autorequire')('./lib', 'Classical', {
  specialCaseModuleNames: {
    cli:         'CLI',
    cli_helpers: 'CLIHelpers',
    languages:   'LANGUAGES',
    underscore:  '_'
  },
  extraGlobalModules: [
    'coffee-script', 'colors', 'fs-tools', 'glob', 'jade', 'optimist', 'showdown', 'spate', 'uglify-js', 'underscore'
  ]
})
