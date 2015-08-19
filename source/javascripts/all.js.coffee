#= require_tree .

#
# Globals

ajax = null
loadedContent = false
$html = $("html")

#
# Misc functions

round = (value, decimals) ->
  Number Math.round(value + "e" + decimals) + "e-" + decimals

arraysEqual = (arr1, arr2) ->
  if arr1.length != arr2.length
    return false
  i = arr1.length
  while i--
    if arr1[i] != arr2[i]
      return false
  true

get = ((a) ->
  if a == ''
    return {}
  b = {}
  i = 0
  while i < a.length
    p = a[i].split('=', 2)
    if p.length == 1
      b[p[0]] = ''
    else
      b[p[0]] = decodeURIComponent(p[1].replace(/\+/g, ' '))
    ++i
  b
)(window.location.search.substr(1).split('&'))

#
# Bind motion disabling/enabling

motionDisabled = Cookies.get("motionDisabled")

if motionDisabled == "yes"
  $html.addClass("motion-disabled")

$ ->
  $(".enable-motion").on "click", ->
    Cookies.set("motionDisabled", "no")
    location.reload(true)

  $(".disable-motion").on "click", ->
    Cookies.set("motionDisabled", "yes")
    location.reload(true)

#
# Feature tests

console.log "Motion disabled: " + motionDisabled

if !feature.historyAPI || !feature.cssTransform || !feature.cssTransition || !feature.css3Dtransform || motionDisabled == "yes"
  console.log("Browser doesn't support one of the features needed, stopping…")
  return
else
  $html.addClass("awesome")

#
# Shim layer for requestAnimationFrame with setTimeout fallback

window.requestAnimFrame = do ->
  window.requestAnimationFrame or window.webkitRequestAnimationFrame or window.mozRequestAnimationFrame or (callback) ->
    window.setTimeout callback, 1000 / 60

#
# Zooming in

zoomTo = (target, stateless = false) ->
  console.log "-----------------"
  console.log "starting a zoomTo"

  if target.length > 0
    # Find pertinent elements
    activeZoomables = $(".z-active")
    parentZoomables = target.parents(".z")
    activeNotParentZoomables = activeZoomables.not(parentZoomables).not(target)

    # Statelessly zoomIn to parents that aren't zoomed in
    parentZoomables.not(".z-active").each ->
      zoomIn( $(@), true )

    # zoomOut from non-parent active zoomables
    activeNotParentZoomables.each ->
      zoomOut( $(@), true )

    # Statefully zoomIn to target
    zoomIn( target, stateless )

zoomToRoot = (stateless = false) ->
  console.log "zooming to root"
  activeZoomables = $(".z-active")
  activeZoomables.each ->
    zoomOut( $(@), true )
  if stateless
    document.title = $("#root").data("title")
  else
    setHistoryToRoot()
  $html.removeClass("z-open z-loading z-loading-failed")

zoomIn = (target, stateless = false) ->
  # Find pertinent elements
  targetID = target.data("id")
  content = target.children(".z-card")
  loadHere = content.children(".article-content").children(".load-article-here")

  console.log "zooming into #{targetID}"

  # AJAX-load more content, if needed
  if loadHere.length > 0
    loadedContent = false
    loadContent( content, target.data("id") )

  if stateless
    document.title = target.data("title")
  else
    # Set history
    setHistoryToTarget(target)

  # Set positions to current location
  target.addClass("z-zooming-in")
  positionsToParent(target, content)

  # Wait a moment and…
  window.setTimeout ->
    # Set classes
    $(".z-current").removeClass("z-current")
    target.addClass("z-active z-current")
    $html.addClass("z-open")

    # Set positions to 0 (zoom in)
    positionsToZero(content)

    # After all positions have been transitioned, finish the zoom
    content.on "transitionend webkitTransitionEnd", (event) ->
      eName = event.originalEvent.propertyName

      if eName == "left" || eName == "top" || eName == "right" || eName == "bottom"
        if positionsMatchZero(content)
          content.off "transitionend webkitTransitionEnd"
          target.addClass("z-visited z-loaded")

          # Append content when it's loaded
          if loadHere.length > 0
            $html.addClass("z-loading")
            if loadedContent
              console.log "content already here"
              loadHere.html( loadedContent )
              $html.removeClass("z-loading z-loading-failed")
              bindZoomTos()
            else
              console.log "content coming later"
              loadHere.one "contentLoaded", ->
                console.log "content arrived"
                loadHere.html( loadedContent )
                $html.removeClass("z-loading z-loading-failed")
                bindZoomTos()

          target.removeClass("z-zooming-in")
  , 1

getParentPositions = (target) ->
  targetWrapper = target
  left = targetWrapper.offset().left
  top = targetWrapper.offset().top
  right = $html.outerWidth() - targetWrapper.outerWidth() - left
  bottom = $html.outerHeight() - targetWrapper.outerHeight() - top
  return [
    parseInt(left),
    parseInt(top),
    parseInt(right),
    parseInt(bottom)
  ]

getContentPositions = (content) ->
  return [
    parseInt( content.css("left") ),
    parseInt( content.css("top") ),
    parseInt( content.css("right") ),
    parseInt( content.css("bottom") )
  ]

positionsToParent = (target, content) ->
  # Set positions to match parent's position (needed for the zoom transitions to work)
  parentPositions = getParentPositions(target)
  content.css
    "left":   parentPositions[0]
    "top":    parentPositions[1]
    "right":  parentPositions[2]
    "bottom": parentPositions[3]

positionsMatchParent = (content, target) ->
  parentPositions = getParentPositions(target)
  contentPositions = getContentPositions(content)
  console.log "do positions match parent?"
  if arraysEqual(parentPositions, contentPositions)
    return true
  else
    return false

positionsToZero = (targetContent) ->
  # Set positions to 0 (makes the zoom happen)
  targetContent.removeAttr("style")
  # targetContent.css
  #   "left": "0"
  #   "top": "0"
  #   "right": "0"
  #   "bottom": "0"

positionsMatchZero = (content) ->
  contentPositions = getContentPositions(content)
  console.log "do positions match zero?"
  if arraysEqual([0,0,0,0], contentPositions)
    return true
  else
    return false

loadContent = (content, id) ->
  # Load content via AJAX and notify about it
  loadHere = content.children(".article-content").children(".load-article-here")
  console.log "trying to load content"
  ajax = $.ajax
    url: id
    error: ->
      $html.addClass("z-loading-failed")
      console.log "loading content failed"
    success: (data) ->
      loadedContent = $(data).find(".article.z-current .load-article-here").html()
      loadHere.trigger("contentLoaded")
      console.log "triggering contentLoaded"
    type: 'GET'

reloadContent = ->
  # Retry loading content via AJAX
  ajax.abort()
  currentZ = $(".z-current")
  $html.removeClass("z-loading-failed")
  loadContent( currentZ.children(".z-card"), currentZ.data("id") )

bindZoomTos = ->
  links = $("a[href^='/']").not(".zoom-out")
  links.off "click"
  links.on "click", (event) ->
    event.preventDefault()
    target = $(@).attr("href")
    zoomTo( $("[data-id='#{target}']") )

#
# zooming out

zoomOut = (target, stateless = false) ->
  if target.length > 0
    # Find pertinent elements
    targetID = target.data("id")
    content = target.children(".z-card")
    parents = target.parent().closest(".z-active")

    if parents.length > 0
      parentZ = parents
    else
      parentZ = $("#root")
      parentIsRoot = true

    console.log "zooming out from #{targetID}"

    # Scroll up, flush content & start zooming out
    content.scrollTop(0)
    target.addClass("z-zooming-out").removeClass("z-loaded")
    flushContentFrom( target )
    positionsToParent(target, content)
    $html.removeClass("z-loading z-loading-failed")

    if stateless
      document.title = target.data("title")
    else
      if parentIsRoot
        setHistoryToRoot()
        $html.removeClass("z-open z-loading z-loading-failed")
      else
        parentZ.addClass("z-current")
        setHistoryToTarget(parentZ)

    # After the transition ends, end zooming
    content.off "transitionend webkitTransitionEnd"
    content.on "transitionend webkitTransitionEnd", (event) ->
      eName = event.originalEvent.propertyName
      if eName == "left" || eName == "top" || eName == "right" || eName == "bottom"
        if positionsMatchParent(content, target)
          positionsToZero(content)
          target.removeClass("z-active z-current z-zooming-out z-zooming-in")
          content.off "transitionend webkitTransitionEnd"

flushContentFrom = (target) ->
  console.log "flushing content"
  # Remove AJAX-loaded content
  flushThis = target.find(".load-article-here")
  if flushThis.length > 0
    flushThis.empty()

#
# Set history to target
setHistoryToTarget = (target) ->
  title = target.data("title")
  targetID = target.data("id")
  console.log "setting history to #{targetID} and #{title}"
  history.pushState({ "targetID" : targetID }, title, targetID)
  document.title = title

#
# Set history to root

setHistoryToRoot = ->
  console.log "setting history to root"
  title = $("#root").data("title")
  history.pushState({ "targetID" : "/" }, title, "/")
  document.title = title



#
# On document ready

$ ->

  #
  # Set history on load and respond to history changes

  if $(".z-current").length > 0
    activeZ = $(".z-current")
  else
    activeZ = $("#root")

  activeZTitle = activeZ.data("title")
  activeZID = activeZ.data("id")
  console.log "setting history to #{activeZID} & #{activeZTitle}"
  history.replaceState({ "targetID" : activeZID }, document.title, activeZID)

  $(window).on "popstate", (event) ->
    targetID = event.originalEvent.state.targetID
    if event.originalEvent.state && targetID
      target = $("[data-id='#{targetID}']")
      console.log "history-zooming to #{targetID}"
      if target.attr("id") == "root"
        zoomToRoot(true)
      else
        zoomTo(target, true)

  #
  # Fastclick

  FastClick.attach document.body

  #
  # Emulate hover on touch

  $(".z").on "touchstart", ->
    $(@).trigger("hover")

  #
  # Bind zoomTo links

  bindZoomTos()

  #
  # Bind zoom out

  zoomOutButton = $(".zoom-out")

  $(document).on "keyup", (event) ->
    if event.keyCode == 27
      zoomOutButton.addClass("hover")
      zoomOut( $(".z-current") )
      window.setTimeout ->
        zoomOutButton.removeClass("hover")
      , 100

  zoomOutButton.on "click", (event) ->
    event.preventDefault()
    zoomOut( $(".z-current") )

  #
  # Bind retry

  $(".load-button").on "click", ->
    reloadContent()
