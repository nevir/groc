require('coffee-script')

module.exports = {
  PACKAGE_INFO: require('./lib/package_info'),
  CLI:          require('./lib/cli'),
  LANGUAGES:    require('./lib/languages'),
  Project:      require('./lib/project'),
  styles:       require('./lib/styles'),
}
