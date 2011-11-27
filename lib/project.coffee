# A core concept of `lidoc` is that your code is grouped into a project, and that there is a certain
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

  # Add source files that should have documentation generated for them to the project.
  add: (fileOrDir) ->
    @log.trace "Project#add(%s)", fileOrDir

    absPath = path.resolve @root, fileOrDir
    stats   = fs.statSync absPath

    # You can add individual files, and we special case that.
    if stats.isFile()
      @files.push absPath

    # Or directories to be recursively walked to find all files under them.
    else if stats.isDirectory()
      @add path.join fileOrDir, p for p in fs.readdirSync fileOrDir when path.basename(p)[0] != '.'

  # Adds a path prefix that should be stripped from source file paths in order to generate relative
  # paths for documentation.
  stripPrefix: (pathPrefix) ->
    @log.trace 'Project#strip(%s)', pathPrefix

    # Prefix paths are either relative to the project root, or absolute
    @stripPrefixes.push "#{path.resolve @root, pathPrefix}/"

  # This is both a performance (over) optimization and debugging aid.  Instead of spamming the
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
    style = new styles.default.Style @

    fileMap = Utils.mapFiles @files, @stripPrefixes
    # If we were given an index file, map that
    if @index
      indexPath = path.resolve @root, @index
      fileMap[indexPath] = 'index' if fileMap[indexPath]

    toProcess = (k for k of fileMap)
    inFlight  = 0

    processFile = =>
      currentFile = toProcess.pop()
      inFlight   += 1
      @log.trace "Processing %s (%d in flight)", currentFile, inFlight

      fs.readFile currentFile, 'utf-8', (error, data) =>
        if error
          @log.error "Failed to process %s: %s", currentFile, error.message
          return callback error

        style.renderFile data, currentFile, fileMap[currentFile], (error) =>
          return callback error if error

          inFlight -= 1
          if toProcess.length > 0
            processFile()
          else
            if inFlight == 0
              style.renderCompleted (error) =>
                return callback error if error

                @log.info ''
                @log.pass 'Documentation generated'
                callback()

    while toProcess.length > 0 and inFlight < @BATCH_SIZE
      processFile()
