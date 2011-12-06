CLIHelpers =


  # Attempt to guess our primary github remote repository
  guessPrimaryGitHubURL: (callback) ->
    # git config lays it all out for us
    childProcess.exec 'git config --list', (error, stdout, stderr) =>
      return error if error

      config = {}
      for line in stdout.split '\n'
        pieces = line.split '='
        config[pieces[0]] = pieces[1]

      # If the user has a tracked gh-pages branch, let's prefer to use its remote
      pagesRemote = config['branch.gh-pages.remote']
      if pagesRemote and config["remote.#{pagesRemote}.url"]
        url = @extractGitHubURL config["remote.#{pagesRemote}.url"]
        return callback null, url if url

      # Next up, their origin remote if it's a valid github remote
      url = @extractGitHubURL config['remote.origin.url']
      return callback null, url if url

      # Last chance, any github-looking remote
      for key, value of config
        url = @extractGitHubURL value
        return callback null, url if url

      callback new Error "Could not guess a GitHub URL for the current repository :("

  # Extract a github URL from a git URL
  extractGitHubURL: (url) ->
    match = url?.match /github\.com:([^\/]+)\/([^\/]+)\.git/
    return null unless match

    "https://github.com/#{match[1]}/#{match[2]}"
