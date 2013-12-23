fs   = require 'fs'
path = require 'path'

fsTools = require 'fs-tools'

StyleHelpers = require '../utils/style_helpers'
Utils        = require '../utils'


module.exports = class Base
  constructor: (project) ->
    @project = project
    @log     = project.log
    @files   = []
    @docs    = []
    @outline = {} # Keyed on target path

  renderFile: (data, fileInfo, callback) ->
    @log.trace 'BaseStyle#renderFile(..., %j, ...)', fileInfo

    @files.push fileInfo

    segments = Utils.splitSource data, fileInfo.language,
      requireWhitespaceAfterToken: !!@project.options.requireWhitespaceAfterToken

    @log.debug 'Split %s into %d segments', fileInfo.sourcePath, segments.length

    Utils.parseDocTags segments, @project, (error) =>
      if error
        @log.error 'Failed to parse doc tags %s: %s\n', fileInfo.sourcePath, error.message, error.stack
        return callback error

      Utils.markdownDocTags segments, @project, (error) =>
        if error
          @log.error 'Failed to markdown doc tags %s: %s\n', fileInfo.sourcePath, error.message, error.stack
          return callback error

        @renderDocTags segments

        Utils.highlightCode segments, fileInfo.language, (error) =>
          if error
            if error.failedHighlights
              for highlight, i in error.failedHighlights
                @log.debug "highlight #{i}:"
                @log.warn   segments[i]?.code.join '\n'
                @log.error  highlight

            @log.error 'Failed to highlight %s as %s: %s', fileInfo.sourcePath, fileInfo.language.name, error.message or error
            return callback error

          Utils.markdownComments segments, @project, (error) =>
            if error
              @log.error 'Failed to markdown %s: %s', fileInfo.sourcePath, error.message
              return callback error

            @outline[fileInfo.targetPath] = StyleHelpers.outlineHeaders segments

            # We also prefer to split out solo headers
            segments = StyleHelpers.segmentizeSoloHeaders segments

            @renderDocFile segments, fileInfo, callback

  # THIS METHOD MUST BE DEFINED BY SUBCLASSES
  # } renderDocTags: (…) -> …

  renderDocFile: (segments, fileInfo, callback) ->
    @log.trace 'BaseStyle#renderDocFile(..., %j, ...)', fileInfo

    docPath = path.resolve @project.outPath, "#{fileInfo.targetPath}.html"

    fsTools.mkdir path.dirname(docPath), '0755', (error) =>
      if error
        @log.error 'Unable to create directory %s: %s', path.dirname(docPath), error.message
        return callback error

      for segment in segments
        segment.markdownedComments = Utils.trimBlankLines segment.markdownedComments
        segment.highlightedCode    = Utils.trimBlankLines segment.highlightedCode
        segment.foldMarker         = Utils.trimBlankLines(segment.foldMarker || '')

      templateContext =
        project:     @project
        segments:    segments
        pageTitle:   fileInfo.pageTitle
        sourcePath:  fileInfo.sourcePath
        targetPath:  fileInfo.targetPath
        projectPath: fileInfo.projectPath
        docPath:     docPath

      # How many levels deep are we?
      pathChunks = path.dirname(fileInfo.targetPath).split(/[\/\\]/)
      if pathChunks.length == 1 && pathChunks[0] == '.'
        templateContext.relativeRoot = ''
      else
        templateContext.relativeRoot = "#{pathChunks.map(-> '..').join '/'}/"

      @docs.push templateContext
      @log.pass "Processed “#{fileInfo.projectPath}”"
      callback()

  # @public
  # @method renderTemplate
  # @param  {Object}          context
  # @param  {String}          source
  # @param  {String}          target
  # @param  {Function}        callback
  # @return {String}
  # @throws {Error}           If @templateFunc has not been set.
  renderTemplate: (context, source, target, callback) ->
    @log.trace 'styles.Base#renderTemplate(context, source, target, callback)'

    throw new Error "@templateFunc must be defined by subclasses!" unless @templateFunc

    context.tableOfContents = @tableOfContents
    try
      data = @templateFunc context
    catch error
      @log.error 'Rendering template for %s failed: %s', source, error.message
      callback error
    delete context.tableOfContents

    return data

  renderCompleted: (callback) ->
    @log.trace 'BaseStyle#renderCompleted(...)'
    @tableOfContents = StyleHelpers.buildTableOfContents @files, @outline
    callback()

  exportCompleted: (callback) ->
    @log.trace 'BaseStyle#exportCompleted(...)'
    callback()
