class BaseStyle
  constructor: (project) ->
    @project = project
    @log     = project.log
    @outline = {}

  renderFile: (data, sourcePath, targetPath, callback) ->
    @log.trace 'BaseStyle#renderFile(..., %s, %s, ...)', sourcePath, targetPath

    language = LANGUAGES.CoffeeScript
    segments = Utils.splitSource data, language
    @log.debug 'Split %s into %d segments', sourcePath, segments.length

    Utils.highlightCode segments, language, (error) =>
      if error
        @log.debug error.pygmentsOutput if error.pygmentsOutput
        @log.error 'Failed to highlight %s: %s', sourcePath, error.message
        return callback error

      Utils.markdownComments segments, @project, (error) =>
        if error
          @log.error 'Failed to markdown %s: %s', sourcePath, error.message
          return callback error

        @outline[targetPath] = Utils.outlineHeaders segments

        @renderDocFile segments, sourcePath, targetPath, callback

  renderDocFile: (segments, sourcePath, targetPath, callback) ->
    @log.trace 'BaseStyle#renderDocFile(..., %s, %s, ...)', sourcePath, targetPath

    throw new Error "@templateFunc must be defined by subclasses!" unless @templateFunc

    docPath = path.resolve @project.outPath, "#{targetPath}.html"

    fsTools.mkdir path.dirname(docPath), 0755, (error) =>
      if error
        @log.error 'Unable to create directory %s: %s', path.dirname(docPath), error.message
        return callback error

      for segment in segments
        segment.markdownedComments = Utils.trimBlankLines segment.markdownedComments
        segment.highlightedCode    = Utils.trimBlankLines segment.highlightedCode

      templateContext =
        project:    @project
        segments:   segments
        sourcePath: sourcePath
        targetPath: targetPath

      # How many levels deep are we?
      pathChunks = path.dirname(targetPath).split(/[\/\\]/)
      if pathChunks.length == 1 && pathChunks[0] == '.'
        templateContext.relativeRoot = ''
      else
        templateContext.relativeRoot = "#{pathChunks.map(-> '..').join '/'}/"

      try
        data = @templateFunc templateContext

      catch error
        @log.error 'Rendering documentation template for %s failed: %s', docPath, error.message
        return callback error

      fs.writeFile docPath, data, 'utf-8', (error) =>
        if error
          @log.error 'Failed to write documentation file %s: %s', docPath, error.message
          return callback error

        @log.pass docPath
        callback()

  renderCompleted: (callback) ->
    @log.trace 'BaseStyle#renderCompleted(...)'

    callback()
