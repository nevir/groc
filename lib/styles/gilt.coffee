path = require 'path'

Default = require './default'

JIRA_TICKET_REGEX = /([A-Z]+-\d+)/g
JIRA_TICKET_URL = 'https://jira.gilt.com/browse/'

# In addition to everything that Default gives us (like doc tags)
# this style will look for certain patterns (like jira tickets)
# and replace them with links, example: FEDUI-1234 should be a link
module.exports = class Gilt extends Default
  constructor: (args...) ->
    super args...

    @sourceAssets = path.join __dirname, 'gilt'

  renderDocTags: (segments) ->
    super segments

    for segment, segmentIndex in segments
      output = segment.comments.join('\n')

      output = output.replace(JIRA_TICKET_REGEX, "<a href=\"#{JIRA_TICKET_URL}$1\">$1</a>")

      segment.comments = output.split '\n'