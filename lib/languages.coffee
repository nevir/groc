# # Supported Languages

module.exports = LANGUAGES =
  Markdown:
    nameMatchers: ['.md', '.markdown','.mkd', '.mkdn', '.mdown']
    commentsOnly: true

  C:
    nameMatchers:      ['.c', '.h']
    pygmentsLexer:     'c'
    singleLineComment: ['//']
    ignorePrefix:      '}'
    foldPrefix:        '^'

  CSharp:
    nameMatchers:      ['.cs']
    pygmentsLexer:     'csharp'
    multiLineComment:  ['/*', '*', '*/']
    singleLineComment: ['//']
    ignorePrefix:      '}'
    foldPrefix:        '^'

  'C++':
    nameMatchers:      ['.cpp', '.hpp', '.c++', '.h++', '.cc', '.hh', '.cxx', '.hxx']
    pygmentsLexer:     'cpp'
    singleLineComment: ['//']
    ignorePrefix:      '}'
    foldPrefix:        '^'

  Clojure:
    nameMatchers:      ['.clj', '.cljs']
    pygmentsLexer:     'clojure'
    singleLineComment: [';;']
    ignorePrefix:      '}'
    foldPrefix:        '^'

  CoffeeScript:
    nameMatchers:      ['.coffee', 'Cakefile']
    pygmentsLexer:     'coffee-script'
    # **CoffeScript's multi-line block-comment styles.**

    # - Variant 1:
    #   (Variant 3 is preferred over this syntax, as soon as the pull-request
    #    mentioned below has been merged into coffee-script's codebase.)
    ###* }
     * Tip: use '-' or '+' for bullet-lists instead of '*' to distinguish
     * bullet-lists visually from this kind of block comments.  The preceding
     * whitespaces in the line-matcher and end-matcher are required. Without
     * them this syntax makes no sense, as it is meant to produce comments
     * like the following in compiled javascript:
     * 
     *     /**
     *      * A sample comment, having a preceding whitespace per line. Useful
     *      * to embed `@doctags` in javascript compiled from coffeescript.
     *      * <= COMBINE THESE TWO CHARS => /
     * 
     * (The the final comment-mark above has been TWEAKED to not raise an error)
     ###
    # - Variant 2:
    ### }
    Uses the the below defined syntax, without preceding `#` per line. This is
    the syntax for what the definition is actually meant for !
    ###
    # - Variant 3:  
    #   (This syntax produces arkward comments in the compiled javascript, if
    #    the pull-request _“[Format block-comments
    #    better](<https://github.com/jashkenas/coffee-script/pull/3132)”_ has 
    #    not been applied to coffee-script's codebase …)
    ### } 
    # The block-comment line-matcher `'#'` also works on lines not starting
    # with `'#'`, because we add unmatched lines to the comments once we are
    # in a multi-line comment-block and until we left them …
    ###
    #- Variant 4:
    #   (This definition matches the format used by YUIDoc to parse CoffeeScript
    #   comments)
    multiLineComment  : [
      # Syntax definition for variant 1.
      '###*',   ' *',   ' ###',
      # Syntax definition for variant 2 and 3.
      '###' ,   '#' ,   '###',
      # Syntax definition for variant 4
      '###*',   '#',    '###'
    ]
    # This flag indicates if the end-mark of block-comments (the third value in
    # the list of 3-tuples above) must correspond to the initial block-mark (the
    # first value in the list of 3-tuples above).  If this flag is missing it
    # defaults to `true`. If true it allows one to nest block-comments in
    # different syntax-definitions, like in handlebars or html+php.
    strictMultiLineEnd:false
    singleLineComment: ['#']
    ignorePrefix:      '}'
    foldPrefix:        '^'

  Go:
    nameMatchers:      ['.go']
    pygmentsLexer:     'go'
    singleLineComment: ['//']
    ignorePrefix:      '}'
    foldPrefix:        '^'

  Handlebars:
    nameMatchers:      ['.handlebars', '.hbs']
    pygmentsLexer:     'html' # TODO: is there a handlebars/mustache lexer? Nope. Lame.
    multiLineComment:  [
      '<!--', '', '-->', # HTML block comments go first, for code highlighting / segment splitting purposes
      '{{!',  '', '}}'   # Actual handlebars block comments
    ]
    # See above for a description of this flag.
    strictMultiLineEnd:true
    # This one differs from the common `ignorePrefix` of all other languages !
    ignorePrefix:      '#'
    foldPrefix:        '^'

  Haskell:
    nameMatchers:      ['.hs']
    pygmentsLexer:     'haskell'
    singleLineComment: ['--']
    ignorePrefix:      '}'
    foldPrefix:        '^'

  Jade:
    nameMatchers:      ['.jade']
    pygmentsLexer:     'jade'
    singleLineComment: ['//', '//-']
    ignorePrefix:      '}'
    foldPrefix:        '^'

  Java:
    nameMatchers:      ['.java']
    pygmentsLexer:     'java'
    singleLineComment: ['//']
    ignorePrefix:      '}'
    foldPrefix:        '^'

  JavaScript:
    nameMatchers:      ['.js']
    pygmentsLexer:     'javascript'
    multiLineComment:  ['/*', '*', '*/']
    singleLineComment: ['//']
    ignorePrefix:      '}'
    foldPrefix:        '^'

  Jake:
    nameMatchers:      ['.jake']
    pygmentsLexer:     'javascript'
    singleLineComment: ['//']
    ignorePrefix:      '}'
    foldPrefix:        '^'

  JSON                :
    nameMatchers      : ['.json']
    pygmentsLexer     : 'json'
    codeOnly          : true

  JSP:
    nameMatchers:      ['.jsp']
    pygmentsLexer:     'jsp'
    multiLineComment:  [
      '<%--', '', '--%>'
    ]
    strictMultiLineEnd:true
    ignorePrefix:      '#'
    foldPrefix:        '^'

  LaTeX:
    nameMatchers:      ['.tex', '.latex', '.sty']
    pygmentsLexer:     'latex'
    singleLineComment: ['%']
    ignorePrefix:      '}'
    foldPrefix:        '^'

  LESS:
    nameMatchers:      ['.less']
    pygmentsLexer:     'sass' # TODO: is there a less lexer? No. Maybe in the future.
    singleLineComment: ['//']
    ignorePrefix:      '}'
    foldPrefix:        '^'

  LiveScript:
    nameMatchers:       ['.ls', 'Slakefile']
    pygmentsLexer:      'livescript'
    multiLineComment:   ['/*', '*', '*/']
    singleLineComment:  ['#']
    ignorePrefix:       '}'
    foldPrefix:         '^'

  Lua:
    nameMatchers:      ['.lua']
    pygmentsLexer:     'lua'
    singleLineComment: ['--']
    ignorePrefix:      '}'
    foldPrefix:        '^'

  Make:
    nameMatchers:      ['Makefile']
    pygmentsLexer:     'make'
    singleLineComment: ['#']
    ignorePrefix:      '}'
    foldPrefix:        '^'

  Mustache:
    nameMatchers:      ['.mustache']
    pygmentsLexer:     'html' # TODO: is there a handlebars/mustache lexer? Nope. Lame.
    multiLineComment:  ['{{!', '', '}}']
    ignorePrefix:      '#'
    foldPrefix:        '^'

  'Objective-C':
    nameMatchers:      ['.m', '.mm']
    pygmentsLexer:     'objc'
    singleLineComment: ['//']
    ignorePrefix:      '}'
    foldPrefix:        '^'

  Perl:
    nameMatchers:      ['.pl', '.pm']
    pygmentsLexer:     'perl'
    singleLineComment: ['#']
    ignorePrefix:      '}'
    foldPrefix:        '^'

  PHP:
    nameMatchers:      [/\.php\d?$/, '.fbp']
    pygmentsLexer:     'php'
    singleLineComment: ['//']
    ignorePrefix:      '}'
    foldPrefix:        '^'

  Puppet:
    nameMatchers:      ['.pp']
    pygmentsLexer:     'puppet'
    singleLineComment: ['#']
    ignorePrefix:      '}'
    foldPrefix:        '^'

  Python:
    nameMatchers:      ['.py']
    pygmentsLexer:     'python'
    singleLineComment: ['#']
    ignorePrefix:      '}'
    foldPrefix:        '^'

  Ruby:
    nameMatchers:      ['.rb', '.ru', '.gemspec']
    pygmentsLexer:     'ruby'
    singleLineComment: ['#']
    ignorePrefix:      '}'
    foldPrefix:        '^'

  Sass:
    nameMatchers:      ['.sass']
    pygmentsLexer:     'sass'
    singleLineComment: ['//']
    ignorePrefix:      '}'
    foldPrefix:        '^'

  SCSS:
    nameMatchers:      ['.scss']
    pygmentsLexer:     'scss'
    multiLineComment:  ['/*', '*', '*/']
    singleLineComment: ['//']
    ignorePrefix:      '}'
    foldPrefix:        '^'

  Shell:
    nameMatchers:      ['.sh']
    pygmentsLexer:     'sh'
    singleLineComment: ['#']
    ignorePrefix:      '}'
    foldPrefix:        '^'

  SQL:
    nameMatchers:      ['.sql']
    pygmentsLexer:     'sql'
    singleLineComment: ['--']
    ignorePrefix:      '}'
    foldPrefix:        '^'
    
  TypeScript:
    nameMatchers:      ['.ts']
    pygmentsLexer:     'ts'
    multiLineComment:  ['/*', '*', '*/']
    singleLineComment: ['//']
    ignorePrefix:      '}'
    foldPrefix:        '^'

  YAML:
    nameMatchers:      ['.yml', '.yaml']
    pygmentsLexer:     'yaml'
    singleLineComment: ['#']
    ignorePrefix:      '}'
    foldPrefix:        '^'
