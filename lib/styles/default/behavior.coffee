tableOfContents = <%= JSON.stringify(tableOfContents) %>

# # Page Behavior

# ## Table of Contents
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
  # WebKit strangeness - calling scrollIntoView() causes the entire page to scroll!
  currentScrollTop = $(window).scrollTop()
  currentNode$[0].scrollIntoView()
  $(window).scrollTop currentScrollTop

setCurrentNodeExpanded = (expanded) ->
  if expanded
    currentNode$.addClass 'expanded'
  else
    currentNode$.removeClass 'expanded'

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

  newNode$ = $(visibleNodes$[newIndex])

  # Remove first, in case it's the same node
  currentNode$.removeClass 'selected'
  newNode$.addClass 'selected'

  currentNode$ = newNode$
  focusCurrentNode()

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
      node$.append """<span class="label">#{node.data.title}</span>"""

    when 'heading'
      node$.append """
        <a class="label" href="#{relativeRoot}#{parentFile.data.targetPath}.html##{node.data.slug}">#{node.data.title}</a>
      """

  if node.outline?.length > 0
    outline$ = $('<ol class="outline"/>')
    outline$.append buildTOCNode c, relativeRoot, node for c in node.outline

    node$.append outline$

  if node.children?.length > 0
    children$ = $('<ol class="children"/>')
    children$.append buildTOCNode c, relativeRoot, parentFile for c in node.children

    node$.append children$

  discloser$ = $('<span class="discloser"/>').prependTo node$.find('> .label')
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
  currentNode$ = fileMap[documentPath].addClass 'selected expanded'
  currentNode$.parents('li').addClass 'expanded'

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
        when 37 then setCurrentNodeExpanded false # left
        when 38 then moveCurrentNode true # up
        when 39 then setCurrentNodeExpanded true # right
        when 40 then moveCurrentNode false # down
        else return

      evt.preventDefault()
