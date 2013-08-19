module.exports = humanize =
  joinSentence: (parts, conjunctive='and') ->
    if parts.length > 2
      [parts[0..-2].join(', '), parts[parts.length - 1]].join(", #{conjunctive} ")
    else
      parts.join(" #{conjunctive} ")

  capitalize: (sentence) ->
    if sentence.length
      parts = sentence.match /^(\s*)([_\*`]*)(\s*)(\w)(.*)$/m
      "#{parts[1]}#{parts[2]}#{parts[3]}#{parts[4].toUpperCase()}#{parts[5]}"
    else
      ''

  article: (word) ->
    if word[0].toLowerCase() in ['a', 'e', 'i', 'o', 'u']
      'an'
    else
      'a'

  pluralizationRules: [
    { regex: /([bcdfghjklmnpqrstvwxz])y$/, replacement: '$1ies' },
    { regex: /(ch|sh|x|ss|s)$/, replacement: '$1es' },
    { regex: /$/, replacement: 's' }
  ]

  pluralize: (word) ->
    return word.replace(rule.regex, rule.replacement) for rule in humanize.pluralizationRules when rule.regex.test word

  gutterify: (text, gutterWidth) ->
    extantMimimumGutterWidth = 0

    if text.match(/^ +/gm)
      extantMinimumGutterWidth = text.match(/^ +/gm).sort()[0].length

    gutter = '            '[0..gutterWidth].slice(1)
    regex = ///^\s{#{extantMinimumGutterWidth}}///gm
    text.replace regex, gutter