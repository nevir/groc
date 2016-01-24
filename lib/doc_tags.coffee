# # Known Doc Tags

humanize = require './utils/humanize'

# This function collapses... spaces
#
# @private
# @method  collapse_space
#
# @param  {String} value This is the value which will be collapsed. The primary
#                        purpose of this method is to allow multiline parameter
#                        descriptions, just like this one.
#
# @return {String}
collapse_space = (value) ->
  value.replace /\s+/g, ' '


# parses function parameters
#
# @public
# @method parseValue
#
# @param  {String} value Text that follows @param
#
# @return {Object}
parseValue = (value) ->
  parts = collapse_space(value).match /^\{([^\}]+)\}\s+(\[?)([\w\.\$]+)(?:=([^\s\]]+))?(\]?)\s*(.*)$/
  types:        (parts[1]?.split /\|{1,2}/g)
  isOptional:   (parts[2] == '[' and parts[5] == ']')
  varName:      parts[3]
  isSubParam:   /\./.test parts[3]
  defaultValue: parts[4]
  description:  parts[6]


# converts parsed values to markdown text
#
# @private
# @method markdown
#
# @param  {Object}   value
# @param  {String[]} value.types
# @param  {Boolean}  value.isOptional=false
# @param  {String}   value.varName
# @param  {Boolean}  value.isSubParam=false
# @param  {String}   [value.defaultValue]
# @param  {String}   [value.description]
#
# @return {String} should be in markdown syntax
parseTypes = (value) ->
  types = (
    for type in value.types
      if type.match /^\.\.\.|\.\.\.$/
        "any number of #{humanize.pluralize '`' + type.replace(/^\.\.\.|\.\.\.$/, "") + '`'}"
      else if type.match /\[\]$/
        "an Array of #{humanize.pluralize '`' + type.replace(/\[\]$/, "") + '`'}"
      else
        "#{humanize.article type} `#{type}`"
  )

  fragments = []

  fragments.push 'is optional' if value.isOptional
  verb = 'must'

  if types.length > 1
    verb = 'can'
  else if types[0] == 'a `mixed`'
    verb = 'can'
    types[0] = 'of any type'
  else if types[0] == 'an Array of Mixeds'
    verb = 'can'
    types[0] = 'an Array of any type'
  else if types[0] == 'any number of Mixeds'
    verb = 'can'
    types[0] = 'any number of arguments of any type'

  fragments.push "#{verb} be #{humanize.joinSentence types, 'or'}"
  fragments.push "has a default value of `#{value.defaultValue}`" if value.defaultValue?

  # Remove leading space and `-` symbol.
  parsedDesc = (/\s*-\s+(.*)/).exec(value.description)
  value.description = parsedDesc[1] unless not parsedDesc

  varNamePrefix = this.varNamePrefix or ''
  varNamePostfix = this.varNamePostfix or ''
  listPrefix = if this.list then (if value.isSubParam then "    *" else "*") else ''

  "#{listPrefix} #{varNamePrefix} `#{value.varName}` #{humanize.joinSentence fragments}.#{varNamePostfix} #{if value.description.length then '<p class="description">' else ''}#{value.description}#{if value.description.length then '</p>' else ''}"


# This is a sample doc tagged block comment
#
# @public
# @module DOC_TAGS
# @type   {Object}
module.exports = DOC_TAGS =
  description:
    section:     'description'
    markdown:    '{value}'

  internal:
    section:     'access'
  'private':
    section:     'access'
  'protected':
    section:     'access'
  'public':
    valuePrefix: 'as'
    section:     'access'
  'static':
    section:     'access'

  constructor:
    section:     'special'
  destructor:
    section:     'special'

  constant:
    section:     'type'
  method:
    section:     'type'
  module:
    section:     'type'
  'package':
    section:     'type'
  property:
    section:     'type'
    parseValue:  parseValue
    markdown:    parseTypes

  accessor:
    section:     'flags'
    markdown:    'is an accessor'
  async:
    section:     'flags'
    markdown:    'is asynchronous'
  asynchronous:  'async'
  getter:
    section:     'flags'
    markdown:    'is a getter'
  recursive:
    section:     'flags'
    markdown:    'is recursive'
  refactor:
    section:     'flags'
    markdown:    'needs to be refactored'
  setter:
    section:     'flags'
    markdown:    'is a setter'

  alias:
    valuePrefix: 'as'
    section:     'metadata'
    markdown:    'is aliased as {value}'
  publishes:
    section:     'metadata'
  requests:
    section:     'metadata'
    markdown:    'makes an ajax request to {value}'
  subscribes:
    valuePrefix: 'to'
    section:     'metadata'
    markdown:    'subscribes to {value}'
  type:
    section:     'metadata'
    markdown:    'of type _{value}_'

  todo:
    section:     'todo'
    markdown:    '<p class="todo">**TODO:** {value}</p>'

  example:
    section:     'example'
    markdown:    '{value}'
  examples:      'example'
  usage:         'example'

  howto:
    section:     'howto'
    markdown:    '{value}'

  # A comment that does not have doc tags in it
  note:
    section:     'discard'
  notes:         'note'

  param:
    section:     'params'
    parseValue:  parseValue
    markdown:    parseTypes
    varNamePrefix: '<p class="param">'
    varNamePostfix: '</p>'
    list:        true
  params:        'param'
  parameters:    'param'

  'return':
    section:     'returns'
    parseValue:  (value) ->
      parts = collapse_space(value).match /^\{([^\}]+)\}\s*(.*)$/
      types:       parts[1].split /\|{1,2}/g
      description: parts[2]
    markdown:     (value) ->
      types = ("#{humanize.article type} `#{type}`" for type in value.types)
      "<p class='doc-section-sub-heading returns'>Returns #{types.join ' or '}</p>#{if value.description.length then '<p class="returns-description">' else ''}#{value.description}#{if value.description.length then '</p>' else ''}"
  returns:       'return'
  throw:
    section:     'returns'
    parseValue:  (value) ->
      parts = collapse_space(value).match /^\{([^\}]+)\}\s*(.*)$/
      types:       parts[1].split /\|{1,2}/g
      description: parts[2]
    markdown:    (value) ->
      types = ("#{humanize.article type} #{type}" for type in value.types)
      "**can throw #{types.join ' or '}**#{if value.description.length then '<br/>(' else ''}#{value.description}#{if value.description.length then ')' else ''}"
  throws:        'throw'

  defaultNoValue:
    section:     'flags'
  defaultHasValue:
    section:     'metadata'
