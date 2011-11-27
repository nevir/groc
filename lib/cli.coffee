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

  opts
    .usage("""
    Usage: lidoc [options] dirs/ sou/rce.files

    You can also specify arguments via a configuration file in the current directory named
    .lidoc.json.  It should contain a mapping between (full) option names and their values.  Search
    paths (the positional arguments) should be set via the key "_".  For example:

      { "_": ["lib", "vendor"], out: "documentation", strip: [] }

    Run lidoc without arguments to use the configuration file.
    """)

    # * Booleans don't jive very well with the `options` call, and they need to be declared prior to
    #   referencing `opts.argv`, or you risk associating positional options with a boolean flag.
    .boolean(['help', 'h', '?', 'github', 'gh', 'verbose', 'very-verbose'])

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

    .options('index',
      describe: "The file to use as the index of the generated documentation."
      alias:    'i'
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
      #   user. This ensures that the common case of `lidoc lib/` will map `lib/some/file.coffee` to
      #   `doc/some/file.html`, and not a redundant and ugly path such as `doc/lib/some/file.html`.
      default: (p for p in opts.argv._ when fs.statSync(p).isDirectory())
    )

    .options('verbose',
      describe: "Output the inner workings of lidoc to help diagnose issues."
    )

    .options('very-verbose',
      describe: "Hey, you asked for it."
    )

  argv = opts.argv
  # * There also does not be a way to enforce that a particular option is an array, so we do this
  #   coercion ourselves.
  argv.strip = [argv.strip] unless util.isArray argv.strip

  return console.log opts.help() if argv.help

  # For the .lidoc.json configuration, we merge it into argv in order to pick up default values such
  # as the root mapping to `process.cwd()`.  Please don't treat this as a contract; it has the
  # potential to change behavior in the future.
  if argv._.length == 0
    try
      config = require path.resolve process.cwd(), '.lidoc.json'
      argv[k] = v for k,v of config

    catch err
      console.log opts.help()
      console.log
      Logger.error "Failed to load .lidoc.json: %s", err.message

      return callback err

  # Squirrel the docs away inside our git directory if we're building for github pages
  argv.out = path.join '.git', 'lidoc-tmp' if argv.github

  project = new Project argv.root, argv.out

  # Set up our logging configuration if the user cares about verbosity
  project.log.minLevel = Logger::LEVELS.DEBUG if argv.verbose
  project.log.minLevel = Logger::LEVELS.TRACE if argv['very-verbose']
  project.log.trace "argv: %j", argv

  # Set up the project
  project.index = argv.index
  project.add         p for p in argv._
  project.stripPrefix p for p in argv.strip when p # --no-strip will result in argv.strip == [false]

  project.generate (error) =>
    return callback error if error or !argv.github

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
