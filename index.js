require('coffee-script')

module.exports = require('autorequire')('./lib', 'Classical', {
  specialCaseModuleNames: {cli: 'CLI', languages: 'LANGUAGES', underscore: '_'},
  extraGlobalModules: [
    'coffee-script', 'colors', 'fs-tools', 'jade', 'optimist', 'showdown', 'uglify-js', 'underscore'
  ]
})
