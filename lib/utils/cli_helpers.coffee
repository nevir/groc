childProcess = require 'child_process'
path         = require 'path'

_ = require 'underscore'


# # Command Line Helpers
module.exports = CLIHelpers =

  # ## configureOptimist

  # [Optimist](https://github.com/substack/node-optimist) fails to provide a few conveniences, so we
  # layer on a little bit of additional structure when defining our options.
  configureOptimist: (opts, config, extraDefaults) ->
    for optName, optConfig of config
      # * We support two tiers of default values.  First, we set up the hard-coded defaults specified
      #   as part of `config`.
      #
      # Also, `default` is a reserved name, hence `defaultVal`.
      defaultVal = extraDefaults?[optName] ? optConfig.default

      # * We also want the ability to specify reactionary default values, so that the user can
      #   inspect the current state of things by tacking on a `--help`.
      defaultVal = defaultVal opts if _.isFunction defaultVal

      # And set it all up with our key as the canonical option name.
      opts.options optName, _(optConfig).extend(default: defaultVal)

  # ## extractArgv

  # In addition to the extended configuration that we desire, we also want special handling for
  # generated values:
  extractArgv: (opts, config) ->
    argv = opts.argv

    # * With regular optimist parsing, you either get an individual value or an array.  For
    #   list-style options, we always want an array.
    for optName, optConfig of config
      if optConfig.type == 'list' and not _.isArray opts.argv[optName]
        argv[optName] = _.compact [ argv[optName] ]

    # * It's also handy to auto-resolve paths.
    for optName, optConfig of config
      argv[optName] = path.resolve argv[optName] if optConfig.type == 'path'

    argv


  # ## guessPrimaryGitHubURL

  guessPrimaryGitHubURL: (repository_url, callback) ->
    # `git config --list` provides information about branches and remotes - everything we need to
    # attempt to guess the project's GitHub repository.
    #
    # There are several states that a GitHub-based repository could be in, and we've probably missed
    # a few.  We attempt to guess it through a few means:
    childProcess.exec 'git config --list', (error, stdout, stderr) =>
      return error if error

      config = {}
      for line in stdout.split '\n'
        pieces = line.split '='
        config[pieces[0]] = pieces[1]

      # * If the user has a tracked `gh-pages` branch, chances are extremely high that its tracked
      #   remote is the correct github project.
      pagesRemote = config['branch.gh-pages.remote'] ? "origin"
      if repository_url?
        return callback null, repository_url, pagesRemote
      else
        if config["remote.#{pagesRemote}.url"]
          url = @extractGitHubURL config["remote.#{pagesRemote}.url"]
          return callback null, url, pagesRemote if url

        # * If that fails, we fall back to the origin remote if it is a GitHub repository.
        url = @extractGitHubURL config['remote.origin.url']
        return callback null, url, pagesRemote if url

        # * We fall back to searching all remotes for a GitHub repository, and choose the first one
        #   we encounter.
        for key, value of config
          url = @extractGitHubURL value
          return callback null, url, pagesRemote if url

        callback new Error "Could not guess a GitHub URL for the current repository :("

  # A quick helper that extracts a GitHub project URL from its repository URL.
  extractGitHubURL: (url) ->
    match = url?.match /github\.com[:\/]([^\/]+)\/([^\/]+)/
    return null unless match

    owner = match[1]
    repo  = if match[2][-4..] == '.git' then match[2][0...-4] else match[2]

    "https://github.com/#{owner}/#{repo}"

module.exports = CLIHelpers
