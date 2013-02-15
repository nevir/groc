# # Supported Languages

module.exports = LANGUAGES =
  Markdown:
    nameMatchers: ['.md']
    commentsOnly: true

  C:
    nameMatchers:      ['.c', '.h']
    pygmentsLexer:     'c'
    singleLineComment: ['//']

  CSharp:
    nameMatchers:      ['.cs']
    pygmentsLexer:     'csharp'
    singleLineComment: ['//']

  'C++':
    nameMatchers:      ['.cpp', '.hpp', '.c++', '.h++', '.cc', '.hh', '.cxx', '.hxx']
    pygmentsLexer:     'cpp'
    singleLineComment: ['//']

  Clojure:
    nameMatchers:      ['.clj']
    pygmentsLexer:     'clojure'
    singleLineComment: [';;']

  CoffeeScript:
    nameMatchers:      ['.coffee', 'Cakefile']
    pygmentsLexer:     'coffee-script'
    singleLineComment: ['#']

  Go:
    nameMatchers:      ['.go']
    pygmentsLexer:     'go'
    singleLineComment: ['//']

  Haskell:
    nameMatchers:      ['.hs']
    pygmentsLexer:     'haskell'
    singleLineComment: ['--']

  Jade:
    nameMatchers:      ['.jade']
    pygmentsLexer:     'jade'
    singleLineComment: ['//', '//-']

  Java:
    nameMatchers:      ['.java']
    pygmentsLexer:     'java'
    singleLineComment: ['//']

  JavaScript:
    nameMatchers:      ['.js']
    pygmentsLexer:     'javascript'
    singleLineComment: ['//']

  Jake:
    nameMatchers:      ['.jake']
    pygmentsLexer:     'javascript'
    singleLineComment: ['//']

  LaTeX:
    nameMatchers:      ['.tex', '.latex', '.sty']
    pygmentsLexer:     'latex'
    singleLineComment: ['%']

  Lua:
    nameMatchers:      ['.lua']
    pygmentsLexer:     'lua'
    singleLineComment: ['--']

  Make:
    nameMatchers:      ['Makefile']
    pygmentsLexer:     'make'
    singleLineComment: ['#']

  'Objective-C':
    nameMatchers:      ['.m', '.mm']
    pygmentsLexer:     'objc'
    singleLineComment: ['//']

  Perl:
    nameMatchers:      ['.pl', '.pm']
    pygmentsLexer:     'perl'
    singleLineComment: ['#']

  PHP:
    nameMatchers:      [/\.php\d?$/, '.fbp']
    pygmentsLexer:     'php'
    singleLineComment: ['//']

  Puppet:
    nameMatchers:      ['.pp']
    pygmentsLexer:     'puppet'
    singleLineComment: ['#']

  Python:
    nameMatchers:      ['.py']
    pygmentsLexer:     'python'
    singleLineComment: ['#']

  Ruby:
    nameMatchers:      ['.rb', '.ru', '.gemspec']
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

  Shell:
    nameMatchers:      ['.sh']
    pygmentsLexer:     'sh'
    singleLineComment: ['#']

  SQL:
    nameMatchers:      ['.sql']
    pygmentsLexer:     'sql'
    singleLineComment: ['--']

  YAML:
    nameMatchers:      ['.yml', '.yaml']
    pygmentsLexer:     'yaml'
    singleLineComment: ['#']
