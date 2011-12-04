tableOfContents = <%= JSON.stringify(tableOfContents) %>

# # Page Behavior

# ## Table of Contents

# Global jQuery references to navigation components we care about.
nav$ = null
toc$ = null

setTableOfContentsActive = (active) ->
  html$ = $('html')

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
  # Remove first, in case it's the same node
  currentNode$.removeClass 'selected'
  newNode$.addClass 'selected'

  currentNode$ = newNode$
  focusCurrentNode()

selectNodeByDocumentPath = (documentPath, headerSlug=null) ->
  currentNode$ = fileMap[documentPath]
  if headerSlug
    for link in currentNode$.find '.outline a'
      urlChunks = $(link).attr('href').split '#'

      if urlChunks[1] == headerSlug
        currentNode$ = $(link).parents('li').first()
        console.log urlChunks, "(#{headerSlug})"
        break

  currentNode$.addClass 'selected expanded'
  currentNode$.parents('li').addClass 'expanded'

  focusCurrentNode()

moveCurrentNode = (up) ->
  visibleNodes$ = toc$.find 'li:visible'

  # Fall back to the first node if anything goes wrong
  newIndex = 0
  for node, i in visibleNodes$
    if node == currentNode$[0]
      newIndex = if up then i - 1 else i + 1
      newIndex = 0 if newIndex < 0
      newIndex = visibleNodes$.length - 1 if newIndex > visibleNodes$.length - 1
      break

  selectNode $(visibleNodes$[newIndex])

visitCurrentNode = ->
  labelLink$ = currentNode$.children('a.label')
  window.location = labelLink$.attr 'href' if labelLink$.length > 0


# ## DOM Construction
#
# Navigation and the table of contents are entirely managed by us.
fileMap = {} # A map of targetPath -> DOM node

buildNav = (relativeRoot) ->
  nav$ = $("""
    <nav>
      <ul class="tools">
        <li class="github"><a href="https://github.com/nevir/groc" title="Project source on GitHub">Project source on GitHub</a></li>
        <li class="toggle">Table of Contents</li>
        <li class="search"><input id="search" type="search"/></li>
      </ul>
      <ol class="toc"/>
      </div>
    </nav>
  """).appendTo $('body')
  toc$ = nav$.find '.toc'

  for node in tableOfContents
    toc$.append buildTOCNode node, relativeRoot

  nav$

buildTOCNode = (node, relativeRoot, parentFile) ->
  node$ = $("""<li class="#{node.type}"/>""")

  switch node.type
    when 'file'
      node$.append """
        <a class="label" href="#{relativeRoot}#{node.data.targetPath}.html">
          <span class="text">#{node.data.title}</span>
        </a>
        <span class="file-path">#{node.data.projectPath}</span>
      """

    when 'folder'
      node$.append """<span class="label"><span class="text">#{node.data.title}</span></span>"""

    when 'heading'
      node$.append """
        <a class="label" href="#{relativeRoot}#{parentFile.data.targetPath}.html##{node.data.slug}">
          <span class="text">#{node.data.title}</span>
        </a>
      """

  if node.outline?.length > 0
    outline$ = $('<ol class="outline"/>')
    outline$.append buildTOCNode c, relativeRoot, node for c in node.outline

    node$.append outline$

  if node.children?.length > 0
    children$ = $('<ol class="children"/>')
    children$.append buildTOCNode c, relativeRoot, parentFile for c in node.children

    node$.append children$

  label$ = node$.find('> .label')
  label$.click -> selectNode node$

  discloser$ = $('<span class="discloser"/>').prependTo label$
  discloser$.addClass 'placeholder' unless node.outline?.length > 0 or node.children?.length > 0
  discloser$.click (evt) ->
    node$.toggleClass 'expanded'
    evt.preventDefault()

  fileMap[node.data.targetPath] = node$ if node.type == 'file'

  node$

$ ->
  relativeRoot = $('meta[name="groc-relative-root"]').attr('content')
  documentPath = $('meta[name="groc-document-path"]').attr('content')

  nav$ = buildNav relativeRoot
  toc$ = nav$.find '.toc'

  # Select the current file, and expand up to it
  selectNodeByDocumentPath documentPath, window.location.hash.replace '#', ''

  # Set up the table of contents toggle
  toggle$ = nav$.find '.toggle'
  toggle$.click (evt) ->
    toggleTableOfContents()

    evt.preventDefault()
    evt.stopPropagation()

  # Prevent text selection
  toggle$.mousedown (evt) ->
    evt.preventDefault()

  # Arrow keys navigate the table of contents whenever it is visible
  $('body').keydown (evt) ->
    if nav$.hasClass 'active'
      switch evt.keyCode
        when 13 then visitCurrentNode() # return
        when 37 then setCurrentNodeExpanded false # left
        when 38 then moveCurrentNode true # up
        when 39 then setCurrentNodeExpanded true # right
        when 40 then moveCurrentNode false # down
        else return

      evt.preventDefault()
