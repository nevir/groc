path = require 'path'
util = require 'util'

FORMAT_REGEXP = /%[sdj%]/g

module.exports = CompatibilityHelpers =
  # `path.sep` was introduced with Node 0.8, so make sure we have it in 0.6.
  pathSep: path.sep || (if process.platform == 'win32' then '\\' else '/')

  # A backport of Node 0.6's util.format
  format: (args...) ->
    return util.format args... if util.format?

    if typeof args[0] != 'string'
      return args.map( (o) -> util.inspect o ).join ' '

    i   = 1
    len = args.length
    str = String(args[0]).replace FORMAT_REGEXP, (x) ->
      return x if i >= len

      switch x
        when '%s' then String args[i++]
        when '%d' then Number args[i++]
        when '%j' then JSON.stringify args[i++]
        when '%%' then '%'
        else x

    while i < len
      x = args[i++]
      if x == null or typeof x != 'object'
        str += ' ' + x
      else
        str += ' ' + util.inspect x

    str
