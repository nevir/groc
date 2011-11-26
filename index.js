require('coffee-script')

module.exports = require('autorequire')('./lib', 'Classical', {
  specialCaseModuleNames: {cli: 'CLI', languages: 'LANGUAGES', underscore: '_'},
  extraGlobalModules: ['colors', 'fs-tools', 'jade', 'optimist', 'showdown', 'underscore']
})
