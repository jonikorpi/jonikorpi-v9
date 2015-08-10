#= require_tree .

#
# Globals

targetContent = null
loadedContent = false
$html = $("html")

#
# Feature tests

console?.log("Viewport Units supported? " + feature.viewportUnits)
console?.log("History API supported? " + feature.historyAPI)
console?.log("CSS 3D transforms supported? " + feature.css3Dtransforms)

if !feature.historyAPI
  console?.log("Browser doesn't support one of the features needed, stopping…")
  return
else
  $html.addClass("awesome")

#
# Shim layer for requestAnimationFrame with setTimeout fallback

window.requestAnimFrame = do ->
  window.requestAnimationFrame or window.webkitRequestAnimationFrame or window.mozRequestAnimationFrame or (callback) ->
    window.setTimeout callback, 1000 / 60

#
# Misc function

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

#
# Zooming in

zoomIn = (target) ->
  console?.log "starting a zoomIn"

  # Cancel ongoing zooms
  zoomingIn = $(".z-zooming-in")
  if zoomingIn.length > 0
    cancelZoomIns(zoomingIn)

  # Find pertinent elements
  content = target.children(".z-card")
  loadHere = content.children(".article-content")

  # AJAX-load more content, if needed
  if loadHere.length > 0
    loadedContent = false
    loadContent( content, target.data("id") )

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
    targetContent = content
    requestAnimFrame(positionsToZero)

    # After all positions have been transitioned, finish the zoom
    content.on "transitionend webkitTransitionEnd", (event) ->
      eName = event.originalEvent.propertyName
      if eName == "left" || eName == "top" || eName == "right" || eName == "bottom"
        if positionsMatchZero(content)
          content.off "transitionend webkitTransitionEnd"
          target.addClass("z-visited z-loaded")
          # Append content when it's loaded
          if loadHere.length > 0
            if loadedContent
              console?.log "content already here"
              loadHere.html( loadedContent )
            else
              console?.log "content coming later"
              loadHere.one "contentLoaded", ->
                console?.log "content arrived"
                loadHere.html( loadedContent )
          target.removeClass("z-zooming-in")
          bindZoomIns()
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
  console?.log "do positions match parent?"
  if arraysEqual(parentPositions, contentPositions)
    return true
  else
    return false

positionsToZero = ->
  # Set positions to 0 (makes the zoom happen)
  targetContent.css
    "left": "0"
    "top": "0"
    "right": "0"
    "bottom": "0"

positionsMatchZero = (content) ->
  contentPositions = getContentPositions(content)
  console?.log "do positions match zero?"
  if arraysEqual([0,0,0,0], contentPositions)
    return true
  else
    return false

loadContent = (content, id) ->
  # Load content via AJAX and notify about it
  loadHere = content.children(".article-content")
  console?.log "trying to load content"
  $.ajax
    url: id
    error: ->
      loadedContent = "<strong>Loading failed. Try refreshing? :(</strong>"
      loadHere.trigger("contentLoaded")
      console?.log "triggering contentLoaded on failure"
    success: (data) ->
      loadedContent = $(data).find(".article.z-current .article-content").html()
      loadHere.trigger("contentLoaded")
      console?.log "triggering contentLoaded"
    type: 'GET'

cancelZoomIns = (zoomingIn) ->
  zoomingIn.each ->
    console?.log "canceling a zoomIn"

    # Find pertinent elements
    target = $(@)
    parent = target.parent().closest(".z-active")
    content = target.children(".z-card")
    loadHere = content.children(".article-content")

    # Cancel zooms stuff
    target.removeClass("z-active z-current z-zooming-in z-loaded")
    targetContent = content
    requestAnimFrame(positionsToZero)

    # Reverse parent-related stuff
    if parent.length > 0
      parent.addClass("z-current")
      setHistoryToTarget(parent)
    else
      $html.removeClass("z-open")
      setHistoryToRoot()

    # Reset history to root
    setHistoryToRoot()

    # Remove zoom ending stuff
    content.off "transitionend webkitTransitionEnd"

    # Remove AJAX loading
    loadHere.off "contentLoaded"
    endedOpeningTransitions = []

bindZoomIns = ->
  links = $("a[href^='/']")
  links.off "click"
  links.on "click", (event) ->
    event.preventDefault()
    target = $(@).attr("href")
    zoomIn( $("[data-id='#{target}']") )

#
# Zooming out

zoomOut = ->
  zoomingIn = $(".z-zooming-in")

  # If there's a zoom going on, cancel it
  if zoomingIn.length > 0
    console?.log "there are zooms going on -> not zooming out"
    cancelZoomIns(zoomingIn)

  # Otherwise, zoom out
  else
    # If there's anything to zoom out from…
    currentZ = $(".z-current")
    if currentZ.length > 0
      console?.log "zooming out"
      # Find pertinent elements
      currentContent = currentZ.children(".z-card")
      parentZ = currentZ.parent().closest(".z-active")

      # Scroll up & start zooming out
      currentContent.scrollTop(0)
      currentZ.addClass("z-zooming-out").removeClass("z-loaded")
      positionsToParent(currentZ, currentContent)

      # If there's a zoomable parent, set it current and history to it
      if parentZ.length > 0
        parentZ.addClass("z-current")
        setHistoryToTarget(parentZ)

      # Else go to root
      else
        $html.removeClass("z-open")
        setHistoryToRoot()

      # After the transition ends, end zooming
      currentContent.on "transitionend webkitTransitionEnd", (event) ->
        eName = event.originalEvent.propertyName
        if eName == "left" || eName == "top" || eName == "right" || eName == "bottom"
          if positionsMatchParent(currentContent, currentZ)
            endZoomOut(currentZ, currentContent)
    else
      console?.log "nothing to zoom out from"

endZoomOut = (currentZ, currentContent) ->
  console?.log "flushing & ending zoomOut"
  flushContentFrom( currentZ )
  targetContent = currentContent
  positionsToZero()
  currentZ.removeClass("z-active z-current z-zooming-out")
  currentContent.off "transitionend webkitTransitionEnd"

flushContentFrom = (target) ->
  console?.log "flushing content"
  # Remove AJAX-loaded content
  flushThis = target.find(".article-content")
  if flushThis.length > 0
    flushThis.empty()

#
# Set history to target
setHistoryToTarget = (target) ->
  console?.log "setting history to target"
  title = target.data("title")
  targetID = target.data("id")
  history.pushState({ "targetID" : targetID }, title, targetID)
  document.title = title

#
# Set history to root

setHistoryToRoot = ->
  console?.log "setting history to root"
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
    activeZTitle = activeZ.data("title")
    activeZID = activeZ.data("id")
    console?.log "setting history to #{activeZID} & #{activeZTitle}"
    history.replaceState({ "targetID" : activeZID }, document.title, activeZID)
  else
    activeZTitle = document.title
    activeZID = "/"

  $(window).on "popstate", (event) ->
    targetID = event.originalEvent.state.targetID
    if event.originalEvent.state && targetID
      # unless targetID == "/"
      console?.log "setting history to #{targetID}"
      zoomIn( $("[data-id='#{targetID}']") )

  #
  # Fastclick

  FastClick.attach document.body

  #
  # Emulate hover on touch

  $(".z").on "touchstart", ->
    $(@).trigger("hover")

  #
  # Bind zoomIn links

  bindZoomIns()

  #
  # Bind zoom out

  zoomOutButton = $(".zoom-out")

  $(document).on "keyup", (event) ->
    if event.keyCode == 27
      zoomOutButton.addClass("hover")
      zoomOut()
      window.setTimeout ->
        zoomOutButton.removeClass("hover")
      , 85

  zoomOutButton.on "click", (event) ->
    event.preventDefault()
    zoomOut()
