# A core concept of `groc` is that your code is grouped into a project, and that there is a certain
# amount of context that it lends to your documentation.
#
# A project:
class Project
  constructor: (root, outPath, minLogLevel=Logger::INFO) ->
    @log = new Logger minLogLevel

    # * Has a single root directory that contains (most of) it.
    @root = path.resolve root
    # * Generally wants documented generated somewhere within its tree.  We default the output path
    #   to be relative to the project root, unless you pass an absolute path.
    @outPath = path.resolve @root, outPath
    # * Contains a set of files to generate documentation from, source code or otherwise.
    @files = []
    # * Should strip specific prefixes of a file's path when generating relative paths for
    #   documentation.  For example, this could be used to ensure that `lib/some/source.file` maps
    #   to `doc/some/source.file` and not `doc/lib/some/source.file`.
    @stripPrefixes = ["#{@root}/"]

  # This is both a performance (over-)optimization and debugging aid.  Instead of spamming the
  # system with file I/O and overhead all at once, we only process a certain number of source files
  # concurrently.  This is similar to what [graceful-fs](https://github.com/isaacs/node-graceful-fs)
  # accomplishes.
  BATCH_SIZE: 10

  # Where the magic happens.
  generate: (callback) ->
    @log.trace 'Project#Generate(...)'
    @log.info 'Generating documentation...'

    # We want to support multiple documentation styles, but we don't expect to have a stable API for
    # that just yet.
    style = new styles.Default @

    fileMap   = Utils.mapFiles @root, @files, @stripPrefixes
    indexPath = path.resolve @root, @index
    toProcess = (k for k of fileMap)
    inFlight  = 0

    processFile = =>
      currentFile = toProcess.pop()
      if currentFile?
        language = Utils.getLanguage currentFile
        unless language?
          @log.warn '%s is not in a supported language, skipping.', currentFile
          return processFile()

        inFlight += 1
        @log.debug "Processing %s (%d in flight)", currentFile, inFlight

      else
        if inFlight == 0
          style.renderCompleted (error) =>
            return callback error if error

            @log.info ''
            @log.pass 'Documentation generated'
            callback()

        # End of the line; we're done chaining processFile()
        return

      fs.readFile currentFile, 'utf-8', (error, data) =>
        if error
          @log.error "Failed to process %s: %s", currentFile, error.message
          return callback error

        fileInfo =
          language:    language
          sourcePath:  currentFile
          projectPath: currentFile.replace ///^#{@root + '/'}///, ''
          targetPath:  if currentFile == indexPath then 'index' else fileMap[currentFile]

        style.renderFile data, fileInfo, (error) =>
            return callback error if error

            inFlight -= 1
            processFile()

    # Kick off the initial batch of files to process.  They'll continue to keep the same number of
    # files in flight by chaining to processFile() once they finish.
    while toProcess.length > 0 and inFlight < @BATCH_SIZE
      processFile()
