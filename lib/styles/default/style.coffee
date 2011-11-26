class Style extends BaseStyle
  constructor: (args...) ->
    super(args...)

    templateData  = fs.readFileSync path.join(__dirname, 'assets', 'code.jade'), 'utf-8'
    @templateFunc = jade.compile templateData

  renderCompleted: (callback) ->
    @log.trace 'styles.default.Style#renderCompleted(...)'

    assetPath = path.resolve @project.outPath, 'assets'
    fsTools.mkdir assetPath, 0755, (error) =>
      if error
        @log.error 'Unable to create directory %s: %s', assetPath, error.message
        return callback error

      fsTools.copy path.resolve(__dirname, 'assets', 'style.css'), path.resolve(assetPath, 'style.css'), (error) =>
        if error
          @log.error 'Unable to copy assets/style.css', assetPath, error.message
          return callback error

        callback()
