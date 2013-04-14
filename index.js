require('coffee-script')
var fs   = require('fs')
var path = require ('path')

module.exports.CLI = require('./lib/cli')
module.exports.PACKAGE_INFO = JSON.parse(fs.readFileSync(path.join(__dirname, 'package.json')))
