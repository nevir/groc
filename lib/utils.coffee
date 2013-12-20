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

  # Code from <http://zetafleet.com/>
  # via <http://blog.simonwillison.net/post/57956816139/escape>
  regexpEscapePattern : /[-[\]{}()*+?.,\\^$|#\s]/g
  regexpEscapeReplace : '\\$&'

  # Escape regular expression characters in a String, an Array of Strings or
  # any Object having a proper toString-method
  regexpEscape: (obj) ->
    if _.isArray obj
      _.invoke(obj, 'replace', @regexpEscapePattern, @regexpEscapeReplace)
    else if _.isString obj
      obj.replace(@regexpEscapePattern, @regexpEscapeReplace)
    else
      @regexpEscape "#{obj}"

  # Detect and return the language that a given file is written in.
  #
  # The language is also annotated with a name property, matching the language's
  # key in LANGUAGES.
  getLanguage: (filePath, languageDefinitions = './languages') ->
    unless @_languageDetectionCache?
      @_languageDetectionCache = []

      LANGUAGES = require(languageDefinitions) if not LANGUAGES?

      for name, language of LANGUAGES
        language.name = name

        for matcher in language.nameMatchers
          # If the matcher is a string, we assume that it's a file extension.
          # Stick it in a regex:
          matcher = ///#{@regexpEscape matcher}$/// if _.isString matcher

          @_languageDetectionCache.push [matcher, language]

    baseName = path.basename filePath

    for pair in @_languageDetectionCache
      return pair[1] if baseName.match pair[0]

  # Map a list of file paths to relative target paths by stripping prefixes.
  mapFiles: (resolveRoot, files, stripPrefixes) ->
    # Ensure that we're dealing with absolute paths across the board.
    files = files.map (f) -> path.resolve resolveRoot, f

    # And that the strip prefixes all end with a /, avoids absolute target path.
    stripPrefixes = stripPrefixes.map (p) ->
      path.join "#{path.resolve resolveRoot, p}#{CompatibilityHelpers.pathSep}"

    # Prefixes are stripped in the order of most specific to least
    # (# of directories deep)
    prefixes = stripPrefixes.sort (a,b) => @pathDepth(b) - @pathDepth(a)

    result = {}

    for absPath in files
      file = absPath

      for stripPath in stripPrefixes
        file = file[stripPath.length..] if file[0...stripPath.length] is stripPath

      # We also strip the extension under the assumption that the consumer of
      # this path map is going to substitute in their own.  Plus, if they care
      # about the extension, they can get it from the keys of the map.
      result[absPath] = if not path.extname(file) then file else file[0...-path.extname(file).length]

    result

  # Attempt to guess strip prefixes for a given set of arguments.
  guessStripPrefixes: (args) ->
    result = []
    for arg in args
      # Most globs look something like dir/**/*.ext, so strip up to the leading *
      arg = arg.replace /\*.*$/, ''

      result.push arg if arg.slice(-1) == CompatibilityHelpers.pathSep

    # For now, we try to avoid ambiguous situations by guessing the FIRST
    # directory given.  The assumption is that you don't want merged paths,
    # but probably did specify the most important source directory first.
    result = _(result).uniq()[...1]

  # How many directories deep is a given path?
  pathDepth: (path) ->
    path.split(/[\/\\]/).length

  # Split source code into segments (comment + code pairs)
  splitSource: (data, language, options={}) ->
    lines = data.split /\r?\n/

    # Always strip shebangs - but don't shift it off the array to
    # avoid the perf hit of walking the array to update indices.
    lines[0] = '' if lines[0][0..1] is '#!'

    # Special case: If the language is comments-only, we can skip pygments
    return [new @Segment [], lines] if language.commentsOnly

    # Special case: If the language is code-only, we can shorten the process
    return [new @Segment lines, []] if language.codeOnly

    segments = []
    currSegment = new @Segment

    # Enforced whitespace after the comment token
    whitespaceMatch = if options.requireWhitespaceAfterToken then '\\s' else '\\s?'

    if language.singleLineComment?
      singleLines = @regexpEscape(language.singleLineComment).join '|'
      aSingleLine = ///
        ^\s*                        # Start a line and skip all indention.
        (?:#{singleLines})          # Match the single-line start but don't capture this group.
        (?:                         # Also don't capture this group …
          #{whitespaceMatch}        # … possibly starting with a whitespace, but
          (.*)                      # … capture anything else in this …
        )?                          # … optional group …
        $                           # … up to the EOL.
      ///


    if language.multiLineComment?
      mlc = language.multiLineComment

      unless (mlc.length % 3) is 0
        throw new Error('Multi-line block-comment definitions must be a list of 3-tuples')

      blockStarts = _.select mlc, (v, i) -> i % 3 == 0
      blockLines  = _.select mlc, (v, i) -> i % 3 == 1
      blockEnds   = _.select mlc, (v, i) -> i % 3 == 2

      # This flag indicates if the end-mark of block-comments (the `blockEnds`
      # list above) must correspond to the initial block-mark (the `blockStarts`
      # above).  If this flag is missing it defaults to `true`.  The main idea
      # is to embed sample block-comments with syntax A in another block-comment 
      # with syntax B. This useful in handlebar's mixed syntax or other language
      # combinations like html+php, which are supported by `pygmentize`.
      strictMultiLineEnd = language.strictMultiLineEnd ? true

      # This map is used to lookup corresponding line- and end-marks.
      blockComments = {}
      for v, i in blockStarts
        blockComments[v] =
          linemark: blockLines[i]
          endmark : blockEnds[i]

      blockStarts = @regexpEscape(blockStarts).join '|'
      blockLines  = @regexpEscape(blockLines).join '|'
      blockEnds   = @regexpEscape(blockEnds).join '|'

      # No need to match for any particular real content in `aBlockStart`, as
      # either `aBlockLine`, `aBlockEnd` or the `inBlock` catch-all fallback
      # handles the real content, in the implementation below.
      aBlockStart = ///
        ^(\s*)                      # Start a line and capture indention, used to reverse indent catch-all fallback lines.
        (#{blockStarts})            # Capture the start-mark, to check the if line- and end-marks correspond, …
        (#{blockLines})?            # … possibly followed by a line, captured to check if its corresponding to the start,
        (?:#{whitespaceMatch}|$)    # … and finished by whitespace OR the EOL.
      ///

      aBlockLine = ///
        ^\s*                        # Start a line and skip all indention.
        (#{blockLines})             # Capture the line-mark to check if it corresponds to the start-mark, …
        (#{whitespaceMatch})        # … possibly followed by whitespace,
        (.*)$                       # … and collect all up to the line end.
      ///

      aBlockEnd = ///
        (#{blockEnds})              # Capture the end-mark to check if it corresponds to the line start,
        (.*)?$                      # … and collect all up to the line end.
      ///

      ###
      # A special case used to capture empty block-comment lines, like the one
      # below this line …
      #
      # … and above this line.
      ###
      aEmptyLine = ///^\s*(?:#{blockLines})$///

    if language.ignorePrefix?
      {ignorePrefix} = language

    if language.foldPrefix?
      {foldPrefix} = language

    if (ignorePrefix? or foldPrefix?) and (singleLines? or blockStarts?)
      stripMarks = []
      stripMarks.push ignorePrefix if ignorePrefix?
      stripMarks.push foldPrefix if foldPrefix?
      stripMarks = @regexpEscape(stripMarks).join '|'

      # Strip final space only if one is required, hence yet present.
      stripSpace = if options.requireWhitespaceAfterToken then '(?:\\s)?' else ''

      # A dirty lap-dance performed here …
      singleStrip = ///
        (                           # Capture this group:
          (?:#{singleLines})        #   The comment marker(s) to keep …
          #{whitespaceMatch}        #   … plus whitespace
        )
        (?:#{stripMarks})           # The marker(s) to strip from result
        #{stripSpace}               #   … plus an optional whitespace.
      /// if singleLines?

      # … and the corresponding gang-bang here. 8-)
      blockStrip = ///
        (                           # Capture this group:
          (?:#{blockStarts})        #   The comment marker(s) to keep …
          (?:#{blockLines})?        #   … optionally plus one more mark
          #{whitespaceMatch}        #   … plus whitespace
        )
        (?:#{stripMarks})           # The marker(s) to strip from result
        #{stripSpace}               #   … plus an optional whitespace.
      /// if blockStarts?

    inBlock   = false
    inFolded  = false
    inIgnored = false

    # Variables used in temporary assignments have been collected here for
    # documentation purposes only. 
    blockline = null
    blockmark = null
    linemark  = null
    space     = null
    endmark   = null
    indention = null
    comment   = null
    code      = null

    for line in lines

      # Match that line to the language's block-comment syntax, if it exists
      if aBlockStart? and not inBlock and (match = line.match aBlockStart)?
        inBlock = true

        # Reusing `match` as a placeholder.
        [match, indention, blockmark, linemark] = match

        # Strip the block-comments start, preserving any inline stuff.
        # We don't touch the `line` itself, as we still need it.
        blockline = line.replace aBlockStart, ''

        # If we found a `linemark`, prepend it (back) to the `blockline`, if it
        # does not correspond to the initial `blockmark`.
        if linemark? and blockComments[blockmark].linemark isnt linemark
          blockline = "#{linemark}#{blockline}"

        # Check if this block-comment is collapsible.
        if foldPrefix? and blockline.indexOf(foldPrefix) is 0

          # We always start a new segment if the current one is not empty or 
          # already folded.
          if inFolded or currSegment.code.length > 0
            segments.push currSegment
            currSegment   = new @Segment

          ### ^ collapsing block-comments:
          # In block-comments only `aBlockStart` may initiate the collapsing.
          # This comment utilizes this syntax, by starting the comment with `^`.
          ###
          inFolded  = true

          # Let's strip the “^” character from our original line, for later use.
          line = line.replace blockStrip, '$1'
          # Also strip it from our `blockline`.
          blockline = blockline[foldPrefix.length...] 

        # Check if this block-comment stays embedded in the code.
        else if ignorePrefix? and blockline.indexOf(ignorePrefix) is 0
          ### } embedded block-comments:
          # In block-comments only `aBlockStart` may initiate the embedding.
          # This comment utilizes this syntax, by starting the comment with `}`.
          ###
          inIgnored = true

          # Let's strip the “}” character from our original line, for later use.
          line = line.replace blockStrip, '$1'
          # Also strip it from our `blockline`.
          blockline = blockline[ignorePrefix.length...] 

        # Block-comments are an important tool to structure code into larger
        # segments, therefore we always start a new segment if the current one
        # is not empty.
        else if currSegment.code.length > 0
          segments.push currSegment
          currSegment   = new @Segment
          inFolded      = false

      # This flag is triggered above.
      if inBlock

        # Catch all lines, unless there is a `blockline` from above.
        blockline = line unless blockline?

        # Match a block-comment's end, even when `inFolded or inIgnored` flags
        # are true …
        if (match = blockline.match aBlockEnd)?

          # Reusing `match` as a placeholder.
          [match, endmark, code] = match

          # The `endmark` must correspond to the `blockmark`'s.
          if not strictMultiLineEnd or blockComments[blockmark].endmark is endmark

            ### Ensure to leave the block-comment, especially single-lines like this one. ###
            inBlock = false

            blockline = blockline.replace aBlockEnd, '' unless (inFolded or inIgnored)

        # Match a block-comment's line, when `inFolded or inIgnored` are false.
        if not (inFolded or inIgnored) and (match = blockline.match aBlockLine)?

          # Reusing `match` as a placeholder.
          [match, linemark, space, comment] = match

          # If we found a `linemark`, prepend it (back) to the `comment`,
          # if it does not correspond to the initial `blockmark`.
          if linemark? and blockComments[blockmark].linemark isnt linemark
            comment = "#{linemark}#{space ? ''}#{comment}"

          blockline = comment

        if inIgnored
          currSegment.code.push line

          # Make sure that the next cycle starts fresh, 
          # if we are going to leave the block.
          inIgnored = false if not inBlock

        else

          if inFolded

            # If the foldMarker is empty assign `blockline` to `foldMarker` …
            if currSegment.foldMarker is ''
              currSegment.foldMarker = line

            # … and collect the `blockline` as code.
            currSegment.code.push line

          else

            # The previous cycle contained code, so lets start a new segment.
            if currSegment.code.length > 0
              segments.push currSegment
              currSegment = new @Segment
  
            # A special case as described in the initialization of `aEmptyLine`.
            if aEmptyLine.test line
              currSegment.comments.push ""

            else
              ###
              Collect all but empty start- and end-block-comment lines, hence
              single-line block-comments simultaneous matching `aBlockStart`
              and `aBlockEnd` have a false `inBlock` flag at this point, are
              included.
              ###
              if not /^\s*$/.test(blockline) or (inBlock and not aBlockStart.test line)
                # Strip leading `indention` from block-comment like the one above
                # to align their content with the initial blockmark.
                if indention? and indention isnt '' and not aBlockLine.test line
                  blockline = blockline.replace ///^#{indention}///, ''

                currSegment.comments.push blockline

              # The `code` may occure immediatly after a block-comment end.
              if code?
                currSegment.code.push code unless inBlock # fool-proof ?
                code = null

        # Make sure the next cycle starts fresh.
        blockline = null

      # Match that line to the language's single line comment syntax.
      #
      # However, we treat all comments beginning with } as inline code commentary
      # and comments starting with ^ cause that comment and the following code
      # block to start folded.
      else if aSingleLine? and (match = line.match aSingleLine)?

        # Uses `match` as a placeholder.
        [match, comment] = match

        if comment? and comment isnt ''

          # } For example, this comment should be treated as part of our code.
          # } Achieved by prefixing the comment's content with “}”
          if ignorePrefix? and comment.indexOf(ignorePrefix) is 0

            # } Hint: never start a new segment here, these comments are code !
            # } If we would do so the segments look visually not so appealing in
            # } the narrowed single-column-view, and we can not embed a series
            # } of comments like these here.

            # Let's strip the “}” character from our documentation
            currSegment.code.push line.replace singleStrip, '$1'

          else

            # The previous cycle contained code, so lets start a new segment
            # and stop any folding.
            if currSegment.code.length > 0
              segments.push currSegment
              currSegment   = new @Segment
              inFolded      = false

            # It's always a good idea to put a comment before folded content
            # like this one here, because folded comments always have their
            # own code-segment in their current implementation (see above).
            # Without a leading comment, the folded code's segment would just
            # follow the above's code segment, which looks visually not so
            # appealing in the narrowed single-column-view.  
            #   
            # TODO: _Alternative (a)_: Improve folded comments to not start a new segment, like embedded comments from above. _(preferred solution)_    
            # TODO: _Alternative (b)_: Improve folded comments visual appearance in single-column view. _(easy solution)_  
            #
            # ^ … if we start this comment with “^” instead of “}” it and all
            # } code up to the next segment's first comment starts folded
            if foldPrefix? and comment.indexOf(foldPrefix) is 0

              # } … so folding stops below, as this is a new segment !
              # Let's strip the “^” character from our documentation
              currSegment.foldMarker = line.replace singleStrip, '$1'

              # And collect it as code.
              currSegment.code.push currSegment.foldMarker
            else
              currSegment.comments.push comment

      # We surely (should) have raw code at this point.
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
    TAG_REGEX = /(?:^|\n)@(\w+)(?:\s+(.*))?/
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
