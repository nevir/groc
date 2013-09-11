fs   = require 'fs'
path = require 'path'

_            = require 'underscore'
coffeeScript = require 'coffee-script'
fsTools      = require 'fs-tools'
jade         = require 'jade'
uglifyJs     = require 'uglify-js'
humanize     = require '../utils/humanize'
Base = require './base'


module.exports = class Default extends Base
  STATIC_ASSETS: ['style.css']

  constructor: (args...) ->
    super(args...)

    @sourceAssets = path.join __dirname, 'default'
    @targetAssets = path.resolve @project.outPath, 'assets'

    templateData  = fs.readFileSync path.join(@sourceAssets, 'docPage.jade'), 'utf-8'
    @templateFunc = jade.compile templateData

  renderCompleted: (callback) ->
    @log.trace 'styles.Default#renderCompleted(...)'

    super (error) =>
      return error if error
      @copyAssets callback

  copyAssets: (callback) ->
    @log.trace 'styles.Default#copyAssets(...)'

    # Even though fsTools.copy creates directories if they're missing - we want a bit more control
    # over it (permissions), as well as wanting to avoid contention.
    fsTools.mkdir @targetAssets, '0755', (error) =>
      if error
        @log.error 'Unable to create directory %s: %s', @targetAssets, error.message
        return callback error
      @log.trace 'mkdir: %s', @targetAssets

      numCopied = 0
      for asset in @STATIC_ASSETS
        do (asset) =>
          assetTarget = path.join @targetAssets, asset
          fsTools.copy path.join(@sourceAssets, asset), assetTarget, (error) =>
            if error
              @log.error 'Unable to copy %s: %s', assetTarget, error.message
              return callback error
            @log.trace 'Copied %s', assetTarget

            numCopied += 1
            @compileScript callback unless numCopied < @STATIC_ASSETS.length

  compileScript: (callback) ->
    @log.trace 'styles.Default#compileScript(...)'

    scriptPath = path.join @sourceAssets, 'behavior.coffee'
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

      #@compressScript scriptSource, callback
      @concatenateScripts scriptSource, callback

  compressScript: (scriptSource, callback) ->
    @log.trace 'styles.Default#compressScript(..., ...)'

    try
      ast = uglifyJs.parser.parse scriptSource
      ast = uglifyJs.uglify.ast_mangle  ast
      ast = uglifyJs.uglify.ast_squeeze ast

      compiledSource = uglifyJs.uglify.gen_code ast

    catch error
      @log.error 'Failed to compress assets/behavior.js: %s', error.message
      return callback error

    @concatenateScripts compiledSource, callback

  concatenateScripts: (scriptSource, callback) ->
    @log.trace 'styles.Default#concatenateScripts(..., ...)'

    jqueryPath = path.join @sourceAssets, 'jquery.min.js'
    fs.readFile jqueryPath, 'utf-8', (error, data) =>
      if error
        @log.error 'Failed to read %s: %s', jqueryPath, error.message
        return callback error

      outputPath = path.join @targetAssets, 'behavior.js'
      fs.writeFile outputPath, data + scriptSource, (error) =>
        if error
          @log.error 'Failed to write %s: %s', outputPath, error.message
          return callback error
        @log.trace 'Wrote %s', outputPath

        callback()

  renderDocTags: (segments) ->
    for segment, segmentIndex in segments when segment.tagSections?

      sections = segment.tagSections
      output = ''
      metaOutput = ''
      accessClasses = 'doc-section'

      accessClasses += " doc-section-#{tag.name}" for tag in sections.access if sections.access?

      segment.accessClasses = accessClasses

      firstPart = []
      firstPart.push tag.markdown for tag in sections.access if sections.access?
      firstPart.push tag.markdown for tag in sections.special if sections.special?
      firstPart.push tag.markdown for tag in sections.type if sections.type?

      metaOutput += "#{humanize.capitalize firstPart.join(' ')}"
      if sections.flags? or sections.metadata?
        secondPart = []
        secondPart.push tag.markdown for tag in sections.flags if sections.flags?
        secondPart.push tag.markdown for tag in sections.metadata if sections.metadata?
        metaOutput += " #{humanize.joinSentence secondPart}"

      output += "<span class='doc-section-header'>#{metaOutput}</span>\n\n" if metaOutput isnt ''

      output += "#{tag.markdown}\n\n" for tag in sections.description if sections.description?

      output += "#{tag.markdown}\n\n" for tag in sections.todo if sections.todo?

      if sections.params?
        output += 'Parameters:\n\n'
        output += "#{tag.markdown}\n\n" for tag in sections.params

      if sections.returns?
        output += (humanize.capitalize(tag.markdown) for tag in sections.returns if sections.returns?).join('<br/>**and** ')

      if sections.howto?
        output += "\n\nHow-To:\n\n#{humanize.gutterify tag.markdown, 0}" for tag in sections.howto

      if sections.example?
        output += "\n\nExample:\n\n#{humanize.gutterify tag.markdown, 4}" for tag in sections.example

      segment.comments = output.split '\n'