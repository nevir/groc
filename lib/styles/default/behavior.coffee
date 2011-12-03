tableOfContents = <%= JSON.stringify(tableOfContents) %>

# # Page Behavior


# ## DOM Construction
#
# Navigation and the table of contents are entirely managed by us.
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
  tocRoot$ = nav$.find '.toc'

  for node in tableOfContents
    tocRoot$.append buildTOCNode node, relativeRoot

buildTOCNode = (node, relativeRoot, parentFile) ->
  node$ = $("""<li class="#{node.type}"/>""")

  switch node.type
    when 'file'
      node$.append """
        <a class="label" href="#{relativeRoot}#{node.data.targetPath}.html">#{node.data.title}</a>
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

  node$

buildOutlineNode = (node, file, relativeRoot) ->
  node$ = $("""<li class="#{node.type}"/>""")

$ ->
  relativeRoot = $('meta[name="lidoc-relative-root"]').attr('content')
  buildNav relativeRoot
