# # Supported Languages

LANGUAGES =
  Markdown:
    nameMatchers: ['.md']
    commentsOnly: true

  CoffeeScript:
    nameMatchers:      ['.coffee']
    pygmentsLexer:     'coffee-script'
    singleLineComment: ['#']

  JavaScript:
    nameMatchers:      ['.js']
    pygmentsLexer:     'javascript'
    singleLineComment: ['//']

  Ruby:
    nameMatchers:      ['.rb']
    pygmentsLexer:     'ruby'
    singleLineComment: ['#']

  Sass:
    nameMatchers:      ['.sass']
    pygmentsLexer:     'sass'
    singleLineComment: ['//']

  SCSS:
    nameMatchers:      ['.scss']
    pygmentsLexer:     'scss'
    singleLineComment: ['//']

  Jade:
    nameMatchers:      ['.jade']
    pygmentsLexer:     'jade'
    singleLineComment: ['//']
