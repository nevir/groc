require('coffee-script')
var fs   = require('fs')
var path = require('path')

module.exports = {
  PACKAGE_INFO: JSON.parse(fs.readFileSync(path.join(__dirname, 'package.json'))),

  CLI:       require('./lib/cli'),
  LANGUAGES: require('./lib/languages'),
  Project:   require('./lib/project'),
  styles:    require('./lib/styles'),
}
