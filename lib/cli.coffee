# # Command Line Interface
#
# Readable command line output is just as important as readable documentation!  It is the first
# interaction that a developer will have with a tool like this, so we want to leave a good
# impression with nicely formatted and readable output.

# It's the caller's responsibility to give us a nice list of ARGV options.  It's only a minor
# annoyance in our binary, but a real win for the crazed developer who wants to be lazy and emulate
# command line behavior.
CLI = (inputArgs, callback) ->
  # As such, we don't want our output bumping up against the shell execution lines and blurring
  # together; use that whitespace with great gusto!
  console.log ''

  actualCallback = callback
  callback = (args...) ->
    # In keeping with our console beautification project, make sure that our output isn't getting
    # too comfortable with the user's next shell line!
    console.log ''

    actualCallback args...

  # [Optimist](https://github.com/substack/node-optimist) is a fantastic options parsing tool, but
  # it does have a few rough edges for our uses:
  #
  # * We don't want to goof up the global optimist instance; it costs us this line of code, and
  #   allows the enterprising scripter to call into our CLI handling, if they're crazy enough to.
  opts = optimist inputArgs


  # ## CLI Overview
  opts
    .usage("""
    Usage: groc [options] "lib/**/*.coffee" doc/*.md

    groc accepts lists of files and (quoted) glob expressions to match the files you would like to
    generate documentation for.

    You can also specify arguments via a configuration file in the current directory named
    .groc.json.  It should contain a mapping between (full) option names and their values.  Search
    paths (the positional arguments) should be set via the key "globs".  For example:

      { "globs": ["lib", "vendor"], out: "documentation", strip: [] }

    Run groc without arguments to use the configuration file.
    """)

    # * Booleans don't jive very well with the `options` call, and they need to be declared prior to
    #   referencing `opts.argv`, or you risk associating positional options with a boolean flag.
    .boolean(['help', 'h', '?', 'github', 'gh', 'verbose', 'very-verbose'])

    # ## CLI Options
    .options('help',
      describe: "You're looking at it."
      alias:    ['h', '?']
    )

    .options('github',
      describe: "Generate your docs in the gh-pages branch of your git repository.  --out is ignored."
      alias:    'gh'
    )

    .options('out',
      describe: "The directory to place generated documentation, relative to the project root."
      alias:    'o'
      default:  'doc'
    )

    .options('except'
      describe: "Glob expression of files to exclude.  Can be specified multiple times."
    )

    .options('index',
      describe: "The file to use as the index of the generated documentation."
      alias:    'i'
      default:  'README.md'
    )

    .options('root',
      describe: "The root directory of the project."
      alias:    'r'
      default:  process.cwd()
    )

    .options('strip',
      describe: "A path prefix to strip when generating documentation paths (or --no-strip)."
      alias:    's'
      # * We want the default value of `--strip` to mirror the first directory given to us by the
      #   user. This ensures that the common case of `groc lib/` will map `lib/some/file.coffee` to
      #   `doc/some/file.html`, and not a redundant and ugly path such as `doc/lib/some/file.html`.
      default: Utils.guessStripPrefixes opts.argv._
    )
 
    .options('verbose',
      describe: "Output the inner workings of groc to help diagnose issues."
    )

    .options('very-verbose',
      describe: "Hey, you asked for it."
    )

  # ## Argument processing
  argv = opts.argv
  # * There also does not be a way to enforce that a particular option is an array, so we do this
  #   coercion ourselves.
  for opt in ['strip', 'except']
    unless Array.isArray argv[opt]
      argv[opt] = if argv[opt]? then [ argv[opt] ] else []

  # And just for our sanity
  argv.globs = argv._

  return console.log opts.help() if argv.help

  # For the .groc.json configuration, we merge it into argv in order to pick up default values such
  # as the root mapping to `process.cwd()`.  Please don't treat this as a contract; it has the
  # potential to change behavior in the future.
  if argv._.length == 0
    try
      configPath = path.resolve process.cwd(), '.groc.json'
      config     = JSON.parse fs.readFileSync configPath
      argv[k]    = v for k,v of config

      # Special case, keep the strip prefix guessing if none was given
      unless 'strip' in config
        argv.strip = Utils.guessStripPrefixes argv.globs

    catch err
      console.log opts.help()
      console.log
      Logger.error "Failed to load .groc.json: %s", err.message

      return callback err

  # Squirrel the docs away inside our git directory if we're building for github pages
  argv.out = path.join '.git', 'groc-tmp' if argv.github

  # Find our matching files and stuff them into a poor-man's set.
  files = {}
  for globExpression in argv.globs
    files[file] = true for file in glob.globSync globExpression

  # Exclude any additional files
  for globExpression in argv.except
    delete files[file] for file in glob.globSync globExpression

  files = (f for f of files)

  # ## Project Configuration
  project = new Project argv.root, argv.out

  # Set up our logging configuration if the user cares about verbosity
  project.log.minLevel = Logger::LEVELS.DEBUG if argv.verbose
  project.log.minLevel = Logger::LEVELS.TRACE if argv['very-verbose']
  project.log.trace "argv: %j", argv

  # Set up the configurable properties on the project.
  project.index = argv.index
  project.files = project.files.concat files
  project.stripPrefixes = project.stripPrefixes.concat argv.strip


  # We can generate w/o much fuss unless we're building for github
  unless argv.github
    project.generate (error) -> callback error

  # ## GitHub
  else
    # Annotate the project with our remote github URL
    utils.CLIHelpers.guessPrimaryGitHubURL (error, url) ->
      if error
        project.log.error error.message
        return callback error

      project.githubURL = url

      # Kick off project generation
      project.generate (error) ->
        return callback error if error

        project.log.info ''
        project.log.info 'Publishing documentation to github...'

        # Dealing with generation for github pages is a bit more involved, so we farm that out to a
        # shell script
        script = childProcess.spawn path.resolve(__dirname, '..', 'scripts', 'publish-git-pages')

        script.stdout.on 'data', (data) -> project.log.info  data.toString().trim()
        script.stderr.on 'data', (data) -> project.log.error data.toString().trim()

        script.on 'exit', (code) ->
          return callback new Error 'Git publish failed' if code != 0

          callback()
