# groc

Groc takes your _documented_ code, and generates documentation that follows the spirit of literate
programming.  Take a look at the [self-generated documentation](http://nevir.github.com/groc/),
and see if it appeals to you!

It is very heavily influenced by [Jeremy Ashkenas](https://github.com/jashkenas)'
[docco](https://github.com/jashkenas/docco), and is an attempt to further enhance the idea with more
features (thus, groc can't tout the same quick 'n dirty principles of docco).


## What does give you?

Groc will:

* Generate documentation in a two-column style for each of your source files.

* Commit and submit your project's documentation to your github pages branch in one fell swoop.

* Generate a searchable table of contents for all documented files and headers within your project.

* Gracefully handle complex hierarchies of source code across multiple folders.

* Read a configuration file so that you don't have to think when you want your documentation built;
  you just type `groc`.


## How?

### Installing groc

Groc depends on [Node](http://nodejs.org/) and [Pygments](http://pygments.org/).  Once you have
those installed, and assuming that your Node install came with [npm](http://npmjs.org/), install
groc via:

    npm install -g groc

For those new to npm, `-g` indicates that you want groc installed as a global for your environment.
You may need to prefix the command with sudo, depending on how you installed node.


### Using groc (CLI)

To generate documentation, just point groc to source files that you want docs for:

    groc *.rb

Groc will also handle extended globbing syntax if you quote arguments:

    groc "lib/**/*.coffee" README.md

By default, groc will drop the generated documentation in the `doc/` folder of your project, and it
will treat `README.md` as the index.  Take a look at your generated docs, and see if everything is
in order!

Once you are pleased with the output, you can push your docs to your github pages branch:

    groc --github "lib/**/*.coffee" README.md

Groc will automagically create and push the `gh-pages` branch if it is missing.


### Configuring groc (.groc.json)

Groc supports a simple JSON configuration format once you know the config values that appeal to you.

Create a `.groc.json` file in your project root, where each key of the JSON object map to arguments
you would pass to the `groc` command.  File names and globs are defined as an array with the key
`globs`.  For example, the configuration for groc is:

    {
      "globs": ["lib/**/*.coffee", "README.md", "lib/styles/*/style.sass", "lib/styles/*/*.jade"],
      "github": true
    }

From now on, if you call `groc` without any arguments, it will use your pre-defined configuration.


## What's in the works?

Groc wants to:

* Fully support hand-held viewing of documentation.  It can almost do this today, but the table of
  contents is horribly broken in the mobile view.

* Provide support for all of your favorite programming/scripting/documentation languages.
