# # Command Line Interface

childProcess = require 'child_process'
fs           = require 'fs'
path         = require 'path'

glob     = require 'glob'
optimist = require 'optimist'

CLIHelpers   = require './utils/cli_helpers'
Logger       = require './utils/logger'
PACKAGE_INFO = require '../package.json'
Project      = require './project'
styles       = require './styles'
Utils        = require './utils'


# Readable command line output is just as important as readable documentation!  It is the first
# interaction that a developer will have with a tool like this, so we want to leave a good
# impression with nicely formatted and readable command line output.
module.exports = CLI = (inputArgs, callback) ->
  # In keeping with our console beautification project, make sure that our output isn't getting
  # too comfortable with the user's next shell line.
  actualCallback = callback
  callback = (args...) ->
    console.log ''

    actualCallback args...

  # We use [Optimist](https://github.com/substack/node-optimist) to parse our command line arguments
  # in a sane manner, and manage the myriad of options.
  opts = optimist inputArgs


  # ## CLI Overview

  # Readable command line output is just as important as readable documentation! It is the first
  # interaction that a developer will have with a tool like this, so we want to leave a good
  # impression with nicely formatted and readable output.
  opts
    .usage("""
    Usage: groc [options] "lib/**/*.coffee" doc/*.md

    groc accepts lists of files and (quoted) glob expressions to match the files you would like to
    generate documentation for.  Any unnamed options are shorthand for --glob arg.

    You can also specify arguments via a configuration file in the current directory named
    .groc.json.  It should contain a mapping between option names and their values.  For example:

      { "glob": ["lib", "vendor"], out: "documentation", strip: [] }
    """)


  # ## CLI Options

  optionsConfig =

    help:
      describe: "You're looking at it."
      alias:   ['h', '?']
      type:     'boolean'

    glob:
      describe: "A file path or globbing expression that matches files to generate documentation for."
      default:  (opts) -> opts.argv._
      type:     'list'

    except:
      describe: "Glob expression of files to exclude.  Can be specified multiple times."
      alias:    'e'
      type:     'list'

    github:
      describe: "Generate your docs in the gh-pages branch of your git repository.  --out is ignored."
      alias:    'gh'
      type:     'boolean'

    'repository-url':
      describe: "Supply your GitHub repository URL (if groc fails to guess it)."
      type:     'string'

    out:
      describe: "The directory to place generated documentation, relative to the project root."
      alias:    'o'
      default:  './doc'
      type:     'path'

    index:
      describe: "The file to use as the index of the generated documentation."
      alias:    'i'
      default:  'README.md'

    'index-page-title':
      describe: "The index's page title in the generated documentation."
      default:  'index'

    root:
      describe: "The root directory of the project."
      alias:    'r'
      default:  '.'
      type:     'path'

    style:
      describe: "The style to use when generating documentation."
      alias:    's'
      default:  'Default'

    showdown:
      describe: "Showdown extensions to load, repeat for more, specifying --[no-]showdown discards default."
      alias:    'sd'
      default:  ['github','table']
      type:     'list'

    strip:
      describe: "A path prefix to strip when generating documentation paths (or --no-strip)."
      alias:    't'

    'whitespace-after-token':
      describe: "Require whitespace after a comment token for a line to be considered a comment."
      default:  true
      type:     'boolean'

    languages:
      describe: "Path to language definition file."
      default:  "#{__dirname}/languages"
      type:     'path'

    silent:
      describe: "Output errors only."

    version:
      describe: "Shows you the current version of groc (#{PACKAGE_INFO.version})"
      alias:    'v'

    verbose:
      describe: "Output the inner workings of groc to help diagnose issues."

   'very-verbose':
      describe: "Hey, you asked for it."


  # ## Argument processing

  # We treat the values within the current project's `.groc.json` as defaults, so that you can
  # easily override the persisted configuration when testing and tweaking.
  #
  # For example, if you have configured your `.groc.json` to include `"github": true`, it is
  # extremely helpful to use `groc --no-github` until you are satisfied with the generated output.
  projectConfigPath = path.resolve '.groc.json'
  try
    projectConfig = JSON.parse fs.readFileSync projectConfigPath
  catch err
    unless err.code == 'ENOENT' || err.code == 'EBADF'
      console.log opts.help()
      console.log
      Logger.error "Failed to load .groc.json: %s", err.message

      return callback err

  # We rely on [CLIHelpers.configureOptimist](utils/cli_helpers.html#configureoptimist) to provide
  # the extra options behavior that we require.
  CLIHelpers.configureOptimist opts, optionsConfig, projectConfig
  #} We have one special case that depends on other defaults...
  opts.default 'strip', Utils.guessStripPrefixes opts.argv.glob unless projectConfig?.strip? and opts.argv.glob?

  argv = CLIHelpers.extractArgv opts, optionsConfig
  # If we're in tracing mode, the parsed options are extremely helpful.
  Logger.trace 'argv: %j', argv if argv['very-verbose']

  # Version checks short circuit before our pretty printing begins, since it is
  # one of those things that you might want to reference from other scripts.
  return console.log PACKAGE_INFO.version if argv.version

  # In keeping with our stance on readable output, we don't want it bumping up
  # against the shell execution lines and blurring together; use that whitespace
  # with great gusto!
  console.log ''

  return console.log opts.help() if argv.help

  # ## Project Generation

  # A [Project](project.html) is just a handy way to configure the generation process, and is in
  # charge of kicking that off.
  project = new Project argv.root, argv.out

  # `--silent`, `--verbose` and `--very-verbose` just impact the logging level of the project.
  project.log.minLevel = Logger::LEVELS.ERROR if argv.silent
  project.log.minLevel = Logger::LEVELS.DEBUG if argv.verbose
  project.log.minLevel = Logger::LEVELS.TRACE if argv['very-verbose']

  # Set up project-specific options as we get them.
  project.options.requireWhitespaceAfterToken = !!argv['whitespace-after-token']
  project.options.showdown = argv.showdown
  project.options.languages = argv.languages

  # We expand the `--glob` expressions into a poor-man's set, so that we can easily remove
  # exclusions defined by `--except` before we add the result to the project's file list.
  files = {}
  for globExpression in argv.glob
    files[file] = true for file in glob.sync globExpression

  for globExpression in argv.except
    delete files[file] for file in glob.sync globExpression

  # There are several properties that we need to configure on a project before we can go ahead and
  # generate its documentation.
  project.index = argv.index
  project.files = (f for f of files)
  project.stripPrefixes = argv.strip

  # `Project#generate` can take some options, such as which style to use.  Since we're generating
  # differently depending on whether or not github is enabled, let's set those up now:
  options =
    indexPageTitle: argv['index-page-title']
    style: styles[argv.style]

  # Good to go!
  unless argv.github
    project.generate options, (error) ->
      callback error

  # ## GitHub
  else
    # We want to be able to annotate generated documentation with the project's GitHub URL.  This is
    # handy for things like generating links directly to each file's source.
    CLIHelpers.guessPrimaryGitHubURL argv['repository-url'], (error, url, remote) ->
      console.log "publish_to_github", error, url, remote

      if error
        project.log.error error.message
        return callback error

      project.githubURL = url

      # We hide the docs inside `.git/groc-tmp` so that we can switch branches without losing the
      # generated output.  It also keeps us out of the business of finding an OS-sanctioned
      # temporary path.
      project.outPath = path.resolve path.join '.git', 'groc-tmp'

      # Dealing with generation for github pages is pretty involved, and requires a lot of back
      # and forth with git.  Rather than descend into callback hell in Node, we farm the logic
      # out to a shell script.

      project.generate options, (error) ->
        return callback error if error

        project.log.info ''
        project.log.info 'Publishing documentation to github...'

        # Roughly, the publishing script:
        #
        # 1. Switches to the `gh-pages` branch (creating it if necessary)
        # 2. Copies the generated docs from `.git/groc-tmp` over any existing files in the branch.
        # 3. Creates a commit with _just_ the generated docs; any additional files are removed.
        # 4. Cleans up and switches back to the user's original branch.
        script = childProcess.spawn path.resolve(__dirname, '..', 'scripts', 'publish-git-pages.sh'), [remote]

        script.stdout.on 'data', (data) -> project.log.info  data.toString().trim()
        script.stderr.on 'data', (data) -> project.log.error data.toString().trim()

        script.on 'exit', (code) ->
          return callback new Error 'Git publish failed' if code != 0

          callback()
