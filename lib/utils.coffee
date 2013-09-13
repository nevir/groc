###
Miscellaneous code fragments reside here.

TODO: should be migrated into `lib/utils`.
###

childProcess = require 'child_process'
path         = require 'path'

_        = require 'underscore'
showdown = require 'showdown'

CompatibilityHelpers = require './utils/compatibility_helpers'
LANGUAGES            = null
DOC_TAGS             = require './doc_tags'
Logger               = require './utils/logger'


module.exports = Utils =
  # Escape regular expression characters in a string
  #
  # Code from http://zetafleet.com/ via http://simonwillison.net/2006/Jan/20/escape/
  regexpEscape: (string) ->
    string.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, '\\$&')

  # Detect and return the language that a given file is written in.
  #
  # The language is also annotated with a name property, matching the laguages key in LANGUAGES.
  getLanguage: (filePath, languageDefinitions = './languages') ->
    unless @_languageDetectionCache?
      @_languageDetectionCache = []

      LANGUAGES = require(languageDefinitions) if not LANGUAGES?

      for name, language of LANGUAGES
        language.name = name

        for matcher in language.nameMatchers
          # If the matcher is a string, we assume that it's a file extension.  Stick it in a regex:
          matcher = ///#{@regexpEscape matcher}$/// if _.isString matcher

          @_languageDetectionCache.push [matcher, language]

    baseName = path.basename filePath

    for pair in @_languageDetectionCache
      return pair[1] if baseName.match pair[0]

  # Map a list of file paths to relative target paths by stripping prefixes off of them.
  mapFiles: (resolveRoot, files, stripPrefixes) ->
    # Ensure that we're dealing with absolute paths across the board
    files = files.map (f) -> path.resolve resolveRoot, f
    # And that the strip prefixes all end with a /, to avoid a target path being absolute.
    stripPrefixes = stripPrefixes.map (p) -> path.join( "#{path.resolve resolveRoot, p}#{CompatibilityHelpers.pathSep}" )

    # Prefixes are stripped in order of most specific to least (# of directories deep)
    prefixes = stripPrefixes.sort (a,b) => @pathDepth(b) - @pathDepth(a)

    result = {}

    for absPath in files
      file = absPath

      for stripPath in stripPrefixes
        file = file[stripPath.length..] if file[0...stripPath.length] == stripPath

      # We also strip the extension under the assumption that the consumer of this path map is going
      # to substitute in their own.  Plus, if they care about the extension, they can get it from
      # the keys of the map.
      result[absPath] = if not path.extname(file) then file else file[0...-path.extname(file).length]

    result

  # Attempt to guess strip prefixes for a given set of arguments.
  guessStripPrefixes: (args) ->
    result = []
    for arg in args
      # Most globs look something like dir/**/*.ext, so strip up to the leading *
      arg = arg.replace /\*.*$/, ''

      result.push arg if arg.slice(-1) == CompatibilityHelpers.pathSep

    # For now, we try to avoid ambiguous situations by guessing the FIRST directory given.  The
    # assumption is that you don't want merged paths, but probably did specify the most important
    # source directory first.
    result = _(result).uniq()[...1]

  # How many directories deep is a given path?
  pathDepth: (path) ->
    path.split(/[\/\\]/).length

  # Split source code into segments (comment + code pairs)
  splitSource: (data, language, options={}) ->
    lines = data.split /\r?\n/

    # Always strip shebangs - but don't shift it off the array to avoid the perf hit of walking the
    # array to update indices.
    lines[0] = '' if lines[0][0..1] == '#!'

    # Special case: If the language is comments-only, we can skip pygments
    return [new @Segment [], lines] if language.commentsOnly

    # Special case: If the language is code-only, we can shorten the process
    return [new @Segment lines, []] if language.codeOnly

    segments = []
    currSegment = new @Segment

    # Enforced whitespace after the comment token
    whitespaceMatch = if options.requireWhitespaceAfterToken then '\\s' else '\\s?'

    if language.singleLineComment?
      singleLineMatcher = ///^\s*(#{language.singleLineComment.join('|')})(?:#{whitespaceMatch}(.*))?$///

    if language.multiLineComment?
      mlc = language.multiLineComment

      blockStarts = _.invoke _.select(mlc, (v, i) -> i % 3 == 0), 'replace', /([\\\*\{\}])/g, '\\\$1'
      blockLines  = _.invoke _.select(mlc, (v, i) -> i % 3 == 1), 'replace', /([\\\*\{\}])/g, '\\\$1'
      blockEnds   = _.invoke _.select(mlc, (v, i) -> i % 3 == 2), 'replace', /([\\\*\{\}])/g, '\\\$1'


      blockStartMatcher = ///^\s*(#{blockStarts.join '|'})(?:#{blockLines.join '|'})?(?:#{whitespaceMatch}(.*))?$///
      blockLineMatcher =  ///^\s*(#{blockLines.join '|'})#{whitespaceMatch}(.*)$///
      blockEndMatcher =   ///^\s*(?:#{blockLines.join '|'})?(.*)(#{blockEnds.join '|'})$///

      blockSingleLineMatcher = ///^\s*(#{blockStarts.join '|'})#{whitespaceMatch}(.*)#{whitespaceMatch}(#{blockEnds.join '|'})///

      if language.singleLineComment?
        singleLineMatcher = ///#{singleLineMatcher.source}|#{blockSingleLineMatcher.source}///
      else
        singleLineMatcher = blockSingleLineMatcher

    if language.ignorePrefix?
      stripIgnorePrefix = ///(#{language.singleLineComment.join '|'})#{whitespaceMatch}#{Utils.regexpEscape language.ignorePrefix}///

    if language.foldPrefix?
      stripFoldPrefix = ///(#{language.singleLineComment.join '|'})#{whitespaceMatch}#{Utils.regexpEscape language.foldPrefix}///

    inBlock = false

    for line in lines

      if inBlock
        if (match = line.match blockEndMatcher)?
          currSegment.comments.push match[1]
          inBlock = false

        else if (match = line.match blockLineMatcher)?
          currSegment.comments.push match[2]

        else
          ###
          # We are in a multi-line block-comment, hence the whole line is part
          # of the comment.  This is especially needed for multi-line comment
          # contents starting immediately at the beginning of a line (without
          # indention, like those in CoffeeScripts).  The `blockLineMatcher`
          # from above can not catch those comments due to the `whitespaceMatch`
          # restrictions from above.  Empty block-comment lines, like the one
          # after this paragraph have no `whitespaceMatch` restriction …
          #
          # @description This comment itself is a multi-line block-comment with
          #             `@doctags`, indention and (needlessly) prefixed by `'#'`.
          # @description The very first comment in this file would render it's
          #              content as code if this `else`-clause is missing.
          ###
          if ///^\s*(#{blockLines.join '|'})$///.test line
            currSegment.comments.push ""
          else
            currSegment.comments.push line

      # Match that line to the language's multi line comment syntax, if it exists
      else if language.multiLineComment? and (match = line.match blockStartMatcher)?

        if currSegment.code.length > 0
          segments.push currSegment
          currSegment = new @Segment

        if line[line.length - 1] == language.foldPrefix
          currSegment.hide = yes

        currSegment.comments.push match[2]
        inBlock = true

      # Match that line to the language's single line comment syntax.
      #
      # However, we treat all comments beginning with } as inline code commentary
      # and comments starting with ^ cause that comment and the following code
      # block to start folded.
      else if (match = line.match singleLineMatcher)?

        value = (match[2] || match[4])

        if value? and value isnt ''

          # } For example, this comment should be treated as part of our code.
          # } Achieved by prefixing the comment's content with “}”
          if stripIgnorePrefix? and value.indexOf(language.ignorePrefix) is 0

            # **Unfold this code ->**
            # ^ The previous cycle contained code, so lets start a new segment,
            # } but only if the previous code-line isn't a comment forced to be
            # } part of the code, as implemented here.  This allows embedding a
            # } series of code-comments, even folded like this one.
            if currSegment.code.length > 0 and \
               not (currSegment.code[currSegment.code.length - 1].match singleLineMatcher)?
              segments.push currSegment
              currSegment = new @Segment

            # Let's strip the “}” character from our documentation
            currSegment.code.push line.replace stripIgnorePrefix, match[1]

          else

            # The previous cycle contained code, so lets start a new segment
            if currSegment.code.length > 0
              segments.push currSegment
              currSegment = new @Segment

            # ^ … if we start this comment with “^” instead of “}” it and all
            # } code up to the next segment's first comment starts folded
            if stripFoldPrefix? and value.indexOf(language.foldPrefix) is 0

              # } … so folding stopped above, as this is a new segment !
              # Let's strip the “^” character from our documentation
              currSegment.foldMarker = line.replace stripFoldPrefix, match[1]

            else
              currSegment.comments.push value

      else
        currSegment.code.push line

    segments.push currSegment

    segments

  # Just a convenient prototype for building segments
  Segment: class Segment
    constructor: (code=[], comments=[], foldMarker='') ->
      @code     = code
      @comments = comments
      @foldMarker = foldMarker

  # Annotate an array of segments by running their code through [Pygments](http://pygments.org/).
  highlightCode: (segments, language, callback) ->
    # Don't bother spawning pygments if we have nothing to highlight
    numCodeLines = segments.reduce ( (c,s) -> c + s.code.length ), 0
    if numCodeLines == 0
      for segment in segments
        segment.highlightedCode = ''

      return callback()

    errListener = (error) ->
      # This appears to only occur when pygmentize is missing:
      Logger.error "Unable to find 'pygmentize' on your PATH.  Please install pygments."
      Logger.info ''

      # Lack of pygments is a one time setup task, we don't feel bad about killing the process
      # off until the user does so.  It's a hard requirement.
      process.exit 1

    pygmentize = childProcess.spawn 'pygmentize', [
      '-l', language.pygmentsLexer
      '-f', 'html'
      '-O', 'encoding=utf-8,tabsize=2'
    ]
    pygmentize.stderr.addListener 'data', (data)  -> callback data.toString()
    pygmentize.stdin.addListener 'error', errListener
    pygmentize.on 'error', errListener


    # We'll just split the output at the end.  pygmentize doesn't stream its output, and a given
    # source file is small enough that it shouldn't matter.
    result = ''
    pygmentize.stdout.addListener 'data', (data) =>
      result += data.toString()

    # v0.8 changed exit/close event semantics.
    match = process.version.match /v(\d+\.\d+)/
    closeEvent = if parseFloat(match[1]) < 0.8 then 'exit' else 'close'

    # We can't include either of the following words ANYWHERE directly adjacent to each other
    # Otherwise, our regex (~10 lines below) will split on them, and the number of code blocks
    # and comment blocks will not be equal.
    seg = 'SEGMENT'
    div = 'DIVIDER'

    pygmentize.addListener closeEvent, (args...) =>
      # pygments spits it out wrapped in `<div class="highlight"><pre>...</pre></div>`.  We want to
      # manage the styling ourselves, so remove that.
      result = result.replace('<div class="highlight"><pre>', '').replace('</pre></div>', '')

      # Extract our segments from the pygmentized source.
      highlighted = "\n#{result}\n".split ///.*<span.*#{seg}\s#{div}.*<\/span>.*///

      if highlighted.length != segments.length
        console.log(result)

        error = new Error CompatibilityHelpers.format 'pygmentize rendered %d of %d segments; expected to be equal',
          highlighted.length, segments.length

        error.pygmentsOutput   = result
        error.failedHighlights = highlighted
        return callback error

      # Attach highlighted source to the highlightedCode property of a Segment.
      for segment, i in segments
        segment.highlightedCode = highlighted[i]

      callback()

    # Rather than spawning pygments for each segment, we stream it all in, separated by 'magic'
    # comments so that we can split the highlighted source back into segments.
    #
    # To further complicate things, pygments doesn't let us cheat with indentation-aware languages:
    # We have to match the indentation of the line following the divider comment.
    mergedCode = ''
    for segment, i in segments
      segmentCode = segment.code.join '\n'

      if i > 0
        # Double negative: match characters that are spaces but not newlines
        indentation = segmentCode.match(/^[^\S\n]+/)?[0] || ''
        if language.singleLineComment?
          mergedCode += "\n#{indentation}#{language.singleLineComment[0]} #{seg} #{div}\n"
        else
          mlc = language.multiLineComment
          mergedCode += "\n#{indentation}#{mlc[0]} #{seg} #{div} #{mlc[2]}\n"

      mergedCode += segmentCode

    pygmentize.stdin.write mergedCode
    pygmentize.stdin.end()

  parseDocTags: (segments, project, callback) ->
    TAG_REGEX = /(?:^|\s)@(\w+)(?:\s+(.*))?/
    TAG_VALUE_REGEX = /^(?:"(.*)"|'(.*)'|\{(.*)\}|(.*))$/

    try
      for segment, segmentIndex in segments when TAG_REGEX.test segment.comments.join('\n')
        tags = []
        currTag = {
          name: 'description'
          value: ''
        }
        tags.push currTag
        tagSections = {}

        for line in segment.comments when line?
          if (match = line.match TAG_REGEX)?
            currTag = {
              name: match[1]
              value: match[2] || ''
            }
            tags.push currTag
          else
            currTag.value += "\n#{line}"

        for tag in tags
          tag.value = tag.value.replace /^\n|\n$/g, ''

          tagDefinition = DOC_TAGS[tag.name]

          unless tagDefinition?
            if tag.value.length == 0
              tagDefinition = 'defaultNoValue'
            else
              tagDefinition = 'defaultHasValue'

          if 'string' == typeof tagDefinition
            tagDefinition = DOC_TAGS[tagDefinition]

          tag.definition = tagDefinition
          tag.section = tagDefinition.section

          if tagDefinition.valuePrefix?
            tag.value = tag.value.replace ///#{tagDefinition.valuePrefix?}\s+///, ''

          if tagDefinition.parseValue?
            tag.value = tagDefinition.parseValue tag.value
          else if not /\n/.test tag.value
            tag.value = tag.value.match(TAG_VALUE_REGEX)[1..].join('')

          tagSections[tag.section] = [] unless tagSections[tag.section]?
          tagSections[tag.section].push tag

        segment.tags = tags
        segment.tagSections = tagSections

    catch error
      return callback error

    callback()

  markdownDocTags: (segments, project, callback) ->
    try
      for segment, segmentIndex in segments when segment.tags?

        for tag in segment.tags
          if tag.definition.markdown?
            if 'string' == typeof tag.definition.markdown
              tag.markdown = tag.definition.markdown.replace /\{value\}/g, tag.value
            else
              tag.markdown = tag.definition.markdown(tag.value)
          else
            if tag.value.length > 0
              tag.markdown = "#{tag.name} #{tag.value}"
            else
              tag.markdown = tag.name

    catch error
      return callback error

    callback()

  # Annotate an array of segments by running their comments through
  # [showdown](https://github.com/coreyti/showdown).
  markdownComments: (segments, project, callback) ->
    converter = new showdown.converter(extensions: project.options.showdown)

    try
      for segment, segmentIndex in segments
        markdown = converter.makeHtml segment.comments.join '\n'
        headers  = []

        # showdown generates header ids by lowercasing & dropping non-word characters.  We'd like
        # something a bit more readable.
        markdown = @gsub markdown, /<h(\d) id="[^"]+">([^<]+)<\/h\d>/g, (match) =>
          header =
            level: parseInt match[1]
            title: match[2]
            slug:  @slugifyTitle match[2]

          header.isFileHeader = true if header.level == 1 && segmentIndex == 0 && match.index == 0

          headers.push header

          "<h#{header.level} id=\"#{header.slug}\">#{header.title}</h#{header.level}>"

        # We attach the rendered markdown to the comment
        segment.markdownedComments = markdown
        # As well as the extracted headers to aid in outline building.
        segment.headers = headers

    catch error
      return callback error

    callback()

  # Sometimes you just don't want any of them hanging around.
  trimBlankLines: (string) ->
    string.replace(/^[\r\n]+/, '').replace(/[\r\n]+$/, '')

  # Given a title, convert it into a URL-friendly slug.
  slugifyTitle: (string) ->
    string.split(/[\s\-\_]+/).map( (s) -> s.replace(/[^\w]/g, '').toLowerCase() ).join '-'

  # replacer is a function that is given the match object, and returns the string to replace with.
  gsub: (string, matcher, replacer) ->
    throw new Error 'You must pass a global RegExp to gsub!' unless matcher.global?

    result = ''
    matcher.lastIndex = 0
    furthestIndex = 0

    while (match = matcher.exec string) != null
      result += string[furthestIndex...match.index] + replacer match

      furthestIndex = matcher.lastIndex

    result + string[furthestIndex...]
