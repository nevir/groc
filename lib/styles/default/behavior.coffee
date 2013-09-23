# # Page Behavior

# ## Table of Contents

# Global jQuery references to navigation components we care about.
html$   = $(document.documentElement).removeClass('no-js').addClass('js')
nav$    = null
toc$    = null
search$ = null

setTableOfContentsActive = (active) ->
  if active
    nav$.addClass  'active'
    html$.addClass 'popped'
  else
    nav$.removeClass  'active'
    html$.removeClass 'popped'

toggleTableOfContents = ->
  setTableOfContentsActive not nav$.hasClass 'active'

# ### Node Navigation
currentNode$ = null

focusCurrentNode = ->
  # We use the first child's offset top rather than toc$.offset().top because there may be borders
  # or other stylistic tweaks that further offset the scrollTop.
  currentNodeTop    = currentNode$.offset().top - toc$.children(':visible').first().offset().top
  currentNodeBottom = currentNodeTop + currentNode$.children('.label').height()

  # If the current node is partially or fully above the top of the viewport, scroll it into view.
  if currentNodeTop < toc$.scrollTop()
    toc$.scrollTop currentNodeTop

  # Similarly, if we're below the bottom of the viewport, scroll up enough to make it visible.
  if currentNodeBottom > toc$.scrollTop() + toc$.height()
    toc$.scrollTop currentNodeBottom - toc$.height()

setCurrentNodeExpanded = (expanded) ->
  if expanded
    currentNode$.addClass 'expanded'
  else
    if currentNode$.hasClass 'expanded'
      currentNode$.removeClass 'expanded'

    # We collapse up to the node's parent if the current node is already collapsed.  This allows
    # a user to quickly spam left to move up the tree.
    else
      parents$ = currentNode$.parents('li')
      selectNode parents$.first() if parents$.length > 0

  focusCurrentNode()

selectNode = (newNode$) ->
  currentNode$ ?= newNode$
  # Remove first, in case it's the same node
  currentNode$.removeClass 'selected'
  newNode$.addClass 'selected'

  focusCurrentNode()

selectNodeByDocumentPath = (documentPath, headerSlug=null) ->
  currentNode$ = fileMap[documentPath]
  if headerSlug
    for link in currentNode$.find '.outline a'
      urlChunks = $(link).attr('href').split '#'

      if urlChunks[1] == headerSlug
        currentNode$ = $(link).parents('li').first()
        break

  currentNode$.addClass 'selected expanded'
  currentNode$.parents('li').addClass 'expanded'

  focusCurrentNode()

moveCurrentNode = (up) ->
  visibleNodes$ = toc$.find 'li:visible:not(.filtered)'
  console.log 'moveCurrentNode', up, visibleNodes$

  # Fall back to the first node if anything goes wrong
  newIndex = 0
  for node, i in visibleNodes$
    console.log 'move?', currentNode$[0]
    if node == currentNode$[0]
      newIndex = if up then i - 1 else i + 1
      newIndex = 0 if newIndex < 0
      newIndex = visibleNodes$.length - 1 if newIndex > visibleNodes$.length - 1
      break

  selectNode $(visibleNodes$[newIndex])

visitCurrentNode = ->
  if currentNode$.hasClass 'current'
    search$.blur()
    window.location
  else
    window.location = currentNode$.children('a.label').attr 'href'


# ## Node Search

# Only show a filter if it matches this many or fewer nodes
MAX_FILTER_SIZE = 10

# An array of of [search string, node, label text] triples
searchableNodes = []
appendSearchNode = (node$) ->
  text$ = node$.find('> .label .text')
  searchableNodes.push [text$.text().toLowerCase(), node$, text$]

currentQuery = ''
searchNodes = (queryString) ->
  queryString = queryString.toLowerCase().replace(/\s+/g, ' ')
  return if queryString == currentQuery
  currentQuery = queryString

  return clearFilter() if queryString == ''

  matcher  = new RegExp (c.replace ///[-[\]{}()*+?.,\\^$|#\s]///, "\\$&" for c in queryString).join '.*'
  matched  = []
  filtered = []

  for nodeInfo in searchableNodes
    if matcher.test nodeInfo[0] then matched.push nodeInfo else filtered.push nodeInfo

  return clearFilter() if matched.length > MAX_FILTER_SIZE

  nav$.addClass 'searching'
  
  # Update the DOM
  for nodeInfo in filtered
    nodeInfo[1].removeClass 'matched-child'
    nodeInfo[1].addClass 'filtered'
    clearHighlight nodeInfo[2]

  for nodeInfo in matched
    nodeInfo[1].removeClass 'filtered matched-child'
    nodeInfo[1].addClass 'matched'

    highlightMatch nodeInfo[2], queryString

    # Filter out our immediate parent
    $(p).addClass 'matched-child' for p in nodeInfo[1].parents 'li'

clearFilter = ->
  nav$.removeClass 'searching'
  currentQuery = ''

  for nodeInfo in searchableNodes
    nodeInfo[1].removeClass 'filtered matched-child matched'
    clearHighlight nodeInfo[2]

highlightMatch = (text$, queryString) ->
  nodeText  = text$.text()
  lowerText = nodeText.toLowerCase()

  markedText    = ''
  furthestIndex = 0

  for char in queryString
    foundIndex    = lowerText.indexOf char, furthestIndex
    markedText   += nodeText[furthestIndex...foundIndex] + "<em>#{nodeText[foundIndex]}</em>"
    furthestIndex = foundIndex + 1

  text$.html markedText + nodeText[furthestIndex...]

clearHighlight = (text$) ->
  text$.text text$.text() # Strip all tags


# ## DOM Construction
#
# Navigation and the table of contents are entirely managed by us.
fileMap = {} # A map of targetPath -> DOM node

buildNav = (metaInfo) ->
  nav$ = $('nav')
  toc$ = nav$.find '.toc'

  $("""
    <ul class="tools">
      <li class="toggle">Table of Contents</li>
      <li class="search">
        <input id="search" type="search" autocomplete="off"/>
      </li>
    </ul>
  """).prependTo nav$

  if metaInfo.githubURL
    # Special case the index to go to the project root
    if metaInfo.documentPath == 'index'
      sourceURL = metaInfo.githubURL
    else
      sourceURL = "#{metaInfo.githubURL}/blob/master/#{metaInfo.projectPath}"

    nav$.find('.tools').prepend """
      <li class="github">
        <a href="#{sourceURL}" title="View source on GitHub">
          View source on GitHub
        </a>
      </li>
    """

  $('li', toc$).each (index) -> buildTOCNode(this, metaInfo)

  nav$

buildTOCNode = (node, metaInfo) ->
  node$ = $(node)

  # } just to clarify: we use it in the `clickLabel`-method below, but can
  # } reference the first time after initializing it a few more lines below
  label$ = node$.find('> .label')

  appendSearchNode node$
  node$.removeClass 'expanded'
  discloser    = label$.find('> .discloser').get(0)

  if node$.hasClass 'file'
    # Persist our references to the node
    targetPath = node$.data('groc-target-path')
    fileMap[targetPath] = node$
    clickLabel = (evt) ->
      console.log 'click', node, node$, evt.target is discloser
      if evt.target is discloser
        node$.toggleClass 'expanded'
        evt.preventDefault()
        return false
      selectNode node$
  else
    clickLabel = (evt) ->
      console.log 'click', node, node$, evt
      node$.toggleClass 'expanded'
      evt.preventDefault()
      return false

  label$.click clickLabel if clickLabel?

  node$

$ ->
  metaInfo =
    relativeRoot: $('meta[name="groc-relative-root"]').attr('content')
    githubURL:    $('meta[name="groc-github-url"]').attr('content')
    documentPath: $('meta[name="groc-document-path"]').attr('content')
    projectPath:  $('meta[name="groc-project-path"]').attr('content')

  nav$    = buildNav metaInfo
  toc$    = nav$.find '.toc'
  search$ = $('#search')

  # Select the current file, and expand up to it
  selectNodeByDocumentPath metaInfo.documentPath, window.location.hash.replace '#', ''

  # We use the search box's focus state to toggle the table of contents.  This ensures that search
  # will always be focused while the toc is up, and that it goes away once the user clicks off.
  search$.focus -> setTableOfContentsActive true

  # However, we don't want to hide the table of contents if you are clicking around in the nav.
  #
  # The blur event doesn't give us the previous event, sadly, so we first trap mousedown events
  lastMousedownTimestamp = null
  nav$.mousedown (evt) ->
    lastMousedownTimestamp = evt.timeStamp unless evt.target == toggle$[0]

  # And we refocus search if we are within a very short duration between the last mousedown in nav$.
  search$.blur (evt) ->
    if evt.timeStamp - lastMousedownTimestamp < 10
      search$.focus()
    else
      setTableOfContentsActive false

  # Set up the table of contents toggle
  toggle$ = nav$.find '.toggle'
  toggle$.click (evt) ->
    if (nav$.hasClass 'active' || search$.is ':focus') then search$.blur() else search$.focus()
    evt.preventDefault()

  # Prevent text selection if the user taps quickly
  toggle$.mousedown (evt) ->
    evt.preventDefault()

  # Arrow keys navigate the table of contents whenever it is visible
  $('body').keydown (evt) ->
    if nav$.hasClass 'active'
      switch evt.keyCode
        when 13 then visitCurrentNode() # Return
        when 27 # ESC
          setTableOfContentsActive(false)
        when 37 then setCurrentNodeExpanded false # left ←
        when 38 then moveCurrentNode true # up ↑
        when 39 then setCurrentNodeExpanded true # right →
        when 40 then moveCurrentNode false # down ↓
        else return
      evt.preventDefault()
    else
      switch evt.keyCode 
        when 13
          search$.focus()
          evt.preventDefault()
        when 27
          setTableOfContentsActive(true)
          evt.preventDefault()

  # searching
  search$.bind 'keyup search', (evt) ->
    searchNodes search$.val()

  search$.keydown (evt) ->
    switch evt.keyCode
      when 9 # TAB
        console.log 'keydown TAB'
        search$.blur()
        setTableOfContentsActive(true) 
        evt.preventDefault()
        return false
      when 27 # ESC
        console.log 'keydown ESC'
        if search$.val().trim() == ''
          search$.blur()
        else
          search$.val ''
        evt.preventDefault()
        return false

  # Make folded code blocks toggleable
  $('.code.folded .marker').each (index, marker) ->
    marker$ = $(marker)
    marker$.click (evt) ->
      marker$.parent().toggleClass 'folded'

  # } toggleTableOfContents()
  return
