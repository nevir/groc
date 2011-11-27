outline = <%= JSON.stringify(outline) %>

# Only show a filter if it matches this many or fewer nodes
MAX_FILTER_SIZE = 20


#############
# Searching #
#############

# A map of search string -> DOM node (the links in the table of contents)
searchableNodes = []
appendSearchNode = (node$) ->
  searchableNodes.push [node$.text().toLowerCase(), node$]

currentQuery = ''
searchNodes = (queryString) ->
  queryString = queryString.toLowerCase().replace(/\s+/, '')
  return if queryString == currentQuery
  currentQuery = queryString

  return clearFilter() if queryString == ''

  matcher  = new RegExp (c.replace /[-[\]{}()*+?.,\\^$|#\s]/, "\\$&" for c in queryString).join '.*'
  matched  = []
  filtered = []

  for nodeInfo in searchableNodes
    if matcher.test nodeInfo[0] then matched.push nodeInfo[1] else filtered.push nodeInfo[1]

  return clearFilter() if matched.length > MAX_FILTER_SIZE

  # Update the DOM
  for node$ in filtered
    node$.removeClass 'matched-child'
    node$.addClass 'filtered'

  for node$ in matched
    node$.removeClass 'filtered matched-child'

    highlightMatch node$, queryString

    # Filter out our immediate parent
    $(p).find('> a').addClass 'matched-child' for p in node$.parent().parents 'li'

clearFilter = ->
  currentQuery = ''
  for nodeInfo in searchableNodes
    node$ = nodeInfo[1]
    node$.removeClass 'filtered matched-child'
    node$.text node$.text()

highlightMatch = (node$, queryString) ->
  nodeText  = node$.text()
  lowerText = nodeText.toLowerCase()

  markedText    = ''
  furthestIndex = 0

  for char in queryString
    foundIndex    = lowerText.indexOf char, furthestIndex
    markedText   += nodeText[furthestIndex...foundIndex] + "<em>#{nodeText[foundIndex]}</em>"
    furthestIndex = foundIndex + 1

  node$.html markedText + nodeText[furthestIndex...]


####################
# DOM Construction #
####################

buildNav = (relativeRoot) ->
  nav$ = $("""
    <nav>
      <ul class="tools">
        <li class="toggle">Table of Contents</li>
        <li class="search"><input id="search" type="search"/></li>
      </ul>
      <ol class="toc"/>
      </div>
    </nav>
  """).appendTo $('body')
  toc$ = nav$.find '.toc'

  files = (f for f of outline).sort()

  for file in files
    filePath = "#{relativeRoot}#{file}.html"

    fileNode$ = $("""
      <li class="file">
        <a href="#{filePath}">#{file}</a>
      </li>
    """).appendTo toc$

    appendSearchNode  fileNode$.find('a')
    appendHeaderNodes fileNode$, filePath, outline[file]

  nav$

appendHeaderNodes = (target$, filePath, nodeList) ->
  return unless nodeList.length > 0

  targetList$ = $('<ol/>').appendTo target$

  for node in nodeList
    node$ = $("""
      <li class="header">
        <a href="#{filePath}##{node.header.slug}">#{node.header.title}</a>
      </li>
    """).appendTo targetList$
    appendSearchNode node$.find('a')

    appendHeaderNodes node$, filePath, node.children

$ ->
  relativeRoot = $('meta[name="lidoc-relative-root"]').attr('content')
  nav$ = buildNav relativeRoot

  search$ = $('#search')
  search$.bind 'keyup search', (evt) =>
    searchNodes search$.val()

  search$.keydown (evt) =>
    if evt.keyCode == 27 # Esc
      if search$.val().trim() == ''
        search$.blur()
      else
        search$.val ''

  search$.focus (evt) => nav$.addClass 'active'
  search$.blur  (evt) => nav$.removeClass 'active'

  nav$.click (evt) =>
    search$.focus()

  nav$.mousedown (evt) =>
    if search$.is(':focus') and evt.target != search$[0]
      evt.preventDefault()
