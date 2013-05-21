fs   = require 'fs'
path = require 'path'
jade = require 'jade'

Default = require './default'

JIRA_TICKET_REGEX = /([A-Z]+-\d+)/g
JIRA_TICKET_URL = 'https://jira.gilt.com/browse/'

UI_STAR_GROUPS = ['admin', 'common', 'controller', 'dom', 'formatter', 'less', 'model', 'nav', 'tracking', 'user', 'validator', 'vendor', 'view', 'x_domain']
UI_STAR_REGEX = ///(["'])(((?:#{UI_STAR_GROUPS.join('|')})\.\w+)(?:\.\w+)*)\1///g
UI_DOCS_MODULE_URL = 'http://ui-docs.corp.gilt.com/'

GITWEB_URL = 'https://gerrit.gilt.com/gitweb.cgi?'

getPackageJson = (pwd) ->
  candidate = path.join pwd, 'package.json'
  if fs.existsSync candidate
    try
      return JSON.parse fs.readFileSync(candidate, 'utf-8')
    catch e
      return null
  return null if pwd == '/'
  getPackageJson path.resolve pwd, '..'

# In addition to everything that Default gives us (like doc tags)
# this style will look for certain patterns (like jira tickets)
# and replace them with links, example: FEDUI-1234 should be a link
# to JIRA and "common.logger" should be a link to ui-docs
module.exports = class Gilt extends Default
  constructor: (args...) ->
    super args...

    packageJson = getPackageJson(path.resolve '.')

    if packageJson?
      repo = packageJson.repository || packageJson.repositories[0]

      # examples:
      #   ssh://gerrit.gilt.com:29418/ui-commons.git
      #   ssh://gerrit_host/ui-commons
      repo_name = repo.url.match(/\/([^\.\/]+)(?:\.git)?$/)?[1]

      path_to_module = repo.path || ''

      module_name = packageJson.name
      version = packageJson.version

      if module_name? and version?
        revision = "#{module_name}-#{version}"
      else
        revision = 'HEAD'

      @project.gitwebURL = "#{GITWEB_URL}p=#{repo_name}.git;hb=#{revision};f=#{path_to_module}"

    @sourceAssets = path.join __dirname, 'gilt'

    templateData  = fs.readFileSync path.join(@sourceAssets, 'docPage.jade'), 'utf-8'
    @templateFunc = jade.compile templateData

  renderDocTags: (segments) ->
    super segments

    for segment, segmentIndex in segments
      output = segment.comments.join '\n'

      output = output.replace JIRA_TICKET_REGEX, "<a href=\"#{JIRA_TICKET_URL}$1\">$1</a>"

      output = output.replace UI_STAR_REGEX, (all, q, fn, pn) -> "<a href=\"#{UI_DOCS_MODULE_URL}#{pn.replace(/\./g, '/')}\">#{q}#{fn}#{q}</a>"

      segment.comments = output.split '\n'