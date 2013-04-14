fs   = require 'fs'
path = require 'path'

package_json_path = path.resolve(__dirname, '../package.json')

module.exports = PACKAGE_INFO = JSON.parse(fs.readFileSync(package_json_path))
