class Style extends BaseStyle
  STATIC_ASSETS: ['style.css']

  constructor: (args...) ->
    super(args...)

    templateData  = fs.readFileSync path.join(__dirname, 'assets', 'code.jade'), 'utf-8'
    @templateFunc = jade.compile templateData

  renderCompleted: (callback) ->
    @log.trace 'styles.default.Style#renderCompleted(...)'

    # Even though fsTools.copy creates directories if they're missing - we want a bit more control
    # over it (permissions), as well as wanting to avoid contention.
    assetPath = path.resolve @project.outPath, 'assets'
    fsTools.mkdir assetPath, 0755, (error) =>
      if error
        @log.error 'Unable to create directory %s: %s', assetPath, error.message
        return callback error
      @log.trace 'mkdir: %s', assetPath

      numCopied = 0
      for asset in @STATIC_ASSETS
        do (asset) =>
          assetTarget = path.resolve assetPath, asset
          fsTools.copy path.resolve(__dirname, 'assets', asset), assetTarget, (error) =>
            if error
              @log.error 'Unable to copy %s: %s', assetTarget, error.message
              return callback error
            @log.trace 'Copied %s', assetTarget

            numCopied += 1
            @compileScript assetPath, callback unless numCopied < @STATIC_ASSETS.length

  compileScript: (assetPath, callback) ->
    @log.trace 'styles.default.Style#compileScript(%s, ...)', assetPath

    scriptPath = path.resolve __dirname, 'assets', 'behavior.coffee.ujs'
    fs.readFile scriptPath, 'utf-8', (error, data) =>
      if error
        @log.error 'Failed to read %s: %s', scriptPath, error.message
        return callback error

      try
        scriptSource = _.template data, @
      catch error
        @log.error 'Failed to interpolate %s: %s', scriptPath, error.message
        return callback error

      try
        scriptSource = coffeeScript.compile scriptSource
        @log.trace 'Compiled %s', scriptPath
      catch error
        @log.debug scriptSource
        @log.error 'Failed to compile %s: %s', scriptPath, error.message
        return callback error

      @compressScripts assetPath, scriptSource, callback

  compressScripts: (assetPath, scriptSource, callback) ->
    @log.trace 'styles.default.Style#compressScripts(%s, ..., ...)', assetPath

    jqueryPath = path.resolve __dirname, 'assets', 'jquery.js'
    fs.readFile jqueryPath, 'utf-8', (error, data) =>
      if error
        @log.error 'Failed to read %s: %s', jqueryPath, error.message
        return callback error

      ast = uglifyJs.parser.parse data + scriptSource
      ast = uglifyJs.uglify.ast_mangle  ast
      ast = uglifyJs.uglify.ast_squeeze ast

      compiledSource = uglifyJs.uglify.gen_code ast

      fs.writeFile path.resolve(assetPath, 'behavior.js'), compiledSource, (error) =>
        if error
          @log.error 'Failed to write assets/behavior.js: %s', error.message
          return callback error
        @log.trace 'Wrote %s', path.resolve(assetPath, 'behavior.js')

        callback()
