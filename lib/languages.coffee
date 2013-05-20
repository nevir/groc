# # Supported Languages

module.exports = LANGUAGES =
  Markdown:
    nameMatchers: ['.md']
    commentsOnly: true

  C:
    nameMatchers:      ['.c', '.h']
    pygmentsLexer:     'c'
    singleLineComment: ['//']
    ignorePrefix:      '}'

  CSharp:
    nameMatchers:      ['.cs']
    pygmentsLexer:     'csharp'
    singleLineComment: ['//']
    ignorePrefix:      '}'

  'C++':
    nameMatchers:      ['.cpp', '.hpp', '.c++', '.h++', '.cc', '.hh', '.cxx', '.hxx']
    pygmentsLexer:     'cpp'
    singleLineComment: ['//']
    ignorePrefix:      '}'

  Clojure:
    nameMatchers:      ['.clj']
    pygmentsLexer:     'clojure'
    singleLineComment: [';;']
    ignorePrefix:      '}'

  CoffeeScript:
    nameMatchers:      ['.coffee', 'Cakefile']
    pygmentsLexer:     'coffee-script'
    singleLineComment: ['#']
    ignorePrefix:      '}'

  Go:
    nameMatchers:      ['.go']
    pygmentsLexer:     'go'
    singleLineComment: ['//']
    ignorePrefix:      '}'

  Handlebars:
    nameMatchers:      ['.handlebars', '.hbs']
    pygmentsLexer:     'html' # TODO: is there a handlebars/mustache lexer? Nope. Lame.
    multiLineComment:  ['{{!', '', '}}']
    ignorePrefix:      '#'

  Haskell:
    nameMatchers:      ['.hs']
    pygmentsLexer:     'haskell'
    singleLineComment: ['--']
    ignorePrefix:      '}'

  Jade:
    nameMatchers:      ['.jade']
    pygmentsLexer:     'jade'
    singleLineComment: ['//', '//-']
    ignorePrefix:      '}'

  Java:
    nameMatchers:      ['.java']
    pygmentsLexer:     'java'
    singleLineComment: ['//']
    ignorePrefix:      '}'

  JavaScript:
    nameMatchers:      ['.js']
    pygmentsLexer:     'javascript'
    singleLineComment: ['//']
    multiLineComment:  ['/*', '*', '*/']
    ignorePrefix:      '}'

  Jake:
    nameMatchers:      ['.jake']
    pygmentsLexer:     'javascript'
    singleLineComment: ['//']
    ignorePrefix:      '}'

  LaTeX:
    nameMatchers:      ['.tex', '.latex', '.sty']
    pygmentsLexer:     'latex'
    singleLineComment: ['%']
    ignorePrefix:      '}'

  LESS:
    nameMatchers:      ['.less']
    pygmentsLexer:     'sass' # TODO: is there a less lexer? No. Maybe in the future.
    singleLineComment: ['//']
    ignorePrefix:      '}'

  Lua:
    nameMatchers:      ['.lua']
    pygmentsLexer:     'lua'
    singleLineComment: ['--']
    ignorePrefix:      '}'

  Make:
    nameMatchers:      ['Makefile']
    pygmentsLexer:     'make'
    singleLineComment: ['#']
    ignorePrefix:      '}'

  Mustache:
    nameMatchers:      ['.mustache']
    pygmentsLexer:     'html' # TODO: is there a handlebars/mustache lexer? Nope. Lame.
    multiLineComment:  ['{{!', '', '}}']
    ignorePrefix:      '#'

  'Objective-C':
    nameMatchers:      ['.m', '.mm']
    pygmentsLexer:     'objc'
    singleLineComment: ['//']
    ignorePrefix:      '}'

  Perl:
    nameMatchers:      ['.pl', '.pm']
    pygmentsLexer:     'perl'
    singleLineComment: ['#']
    ignorePrefix:      '}'

  PHP:
    nameMatchers:      [/\.php\d?$/, '.fbp']
    pygmentsLexer:     'php'
    singleLineComment: ['//']
    ignorePrefix:      '}'

  Puppet:
    nameMatchers:      ['.pp']
    pygmentsLexer:     'puppet'
    singleLineComment: ['#']
    ignorePrefix:      '}'

  Python:
    nameMatchers:      ['.py']
    pygmentsLexer:     'python'
    singleLineComment: ['#']
    ignorePrefix:      '}'

  Ruby:
    nameMatchers:      ['.rb', '.ru', '.gemspec']
    pygmentsLexer:     'ruby'
    singleLineComment: ['#']
    ignorePrefix:      '}'

  Sass:
    nameMatchers:      ['.sass']
    pygmentsLexer:     'sass'
    singleLineComment: ['//']
    ignorePrefix:      '}'

  SCSS:
    nameMatchers:      ['.scss']
    pygmentsLexer:     'scss'
    singleLineComment: ['//']
    ignorePrefix:      '}'

  Shell:
    nameMatchers:      ['.sh']
    pygmentsLexer:     'sh'
    singleLineComment: ['#']
    ignorePrefix:      '}'

  SQL:
    nameMatchers:      ['.sql']
    pygmentsLexer:     'sql'
    singleLineComment: ['--']
    ignorePrefix:      '}'

  YAML:
    nameMatchers:      ['.yml', '.yaml']
    pygmentsLexer:     'yaml'
    singleLineComment: ['#']
    ignorePrefix:      '}'