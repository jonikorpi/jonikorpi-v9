#= require_tree .

#
# Shim layer for requestAnimationFrame with setTimeout fallback

window.requestAnimFrame = do ->
  window.requestAnimationFrame or window.webkitRequestAnimationFrame or window.mozRequestAnimationFrame or (callback) ->
    window.setTimeout callback, 1000 / 60

#
# Rounding function

round = (value, decimals) ->
  Number Math.round(value + "e" + decimals) + "e-" + decimals

#
# Zooms

zoomIn = (target) ->
  # target = $("[data-id='#{target}']")
  $(".z-current").removeClass("z-current")
  target.addClass("z-active z-current")
  $("body").addClass("z-open")
  setHistoryToTarget(target)

zoomOut = ->
  currentZ = $(".z-current")
  parentZ = currentZ.parent().closest(".z-active")
  if parentZ.length > 0
    currentZ.removeClass("z-active z-current")
    parentZ.addClass("z-current")
    setHistoryToTarget(parentZ)
  else
    $("body").removeClass("z-open")
    currentZ.removeClass("z-active z-current")
    setHistoryToRoot()

#
# Set history to target
setHistoryToTarget = (target) ->
  history.pushState({ "targetID" : target.data("id") }, target.data("title"), target.data("id"))

#
# Set history to root

setHistoryToRoot = ->
  title = $("#root").data("title")
  history.pushState({ "targetID" : "/" }, title, "/")
  document.title = title

#
# On document ready

$ ->

  #
  # Fastclick

  FastClick.attach document.body

  #
  # Emulate hover on touch

  $(".z").on "touchstart", ->
    $(@).trigger("hover")

  #
  # Bind zoom in

  $(".z-anchor").on "click", (event) ->
    event.preventDefault()
    thisZ = $(@).closest(".z")
    # zoomIn( thisZ.data("id") )
    zoomIn(thisZ)

  #
  # Bind zoom out

  $(document).on "keyup", (event) ->
    if event.keyCode == 27
      zoomOut()

  #
  # Support history state changes

  # history.replaceState({ "targetID" : window.Engine.currentZoomableID }, document.title, window.Engine.currentZoomableID)
  #
  # $(window).on "popstate", (event) ->
  #   console.log "POPSTATE"
  #   if event.originalEvent.state && event.originalEvent.state.targetID
  #     console.log "POPSTATE TARGETID: #{event.originalEvent.state.targetID}"
  #     zoomIn(event.originalEvent.state.targetID)

  #
  # Set history API stuff

  # unless statelessZoom
  #   if targetID == window.Engine.initialZoomable.data("id")
  #     history.pushState({ "targetID" : window.Engine.initialZoomable.data("id") }, $("html head title").text(), "/")
  #     console.log "Clearing hash"
  #   else
  #     history.pushState({ "targetID" : targetID }, $target.data("title"), targetID)
  #     console.log "Setting hash to #{targetID} with #{$target.data("title")}"
  # document.title = $target.data("title")


  #
  # Javascript srsly

  # Feature tests
  # console.log("Viewport Units supported? " + feature.viewportUnits)
  # console.log("History API supported? " + feature.historyAPI)
  # console.log("CSS 3D transforms supported? " + feature.css3Dtransforms)
  #
  # if !feature.viewportUnits || !feature.historyAPI || !feature.css3Dtransforms
  #   console.log("Browser doesn't support one of the features needed, stopping…")
  #   return
  # else
  #   $("html").addClass("awesome")



#
#   #
#   # Config
#
#   window.Engine =
#     htmlTag: $("html")
#     viewport: $("body")
#     canvas: $(".site-canvas")
#     initialZoomable: $(".initial-zoomable")
#     zoomableAnchor: ".zoomable-anchor"
#     zoomableLink: ".zoomable-link, section a[href^='/']"
#     zoomOutButton: $("#zoom-out")
#     baseTransitionTime: 0.414
#     transitionEasing:  "cubic-bezier(0.146, 0.0, 0.0, 0.236)"
#     currentScale: 1
#     currentX: 0
#     currentY: 0
#     currentZoomableID: $("html").data("current-zoomable")
#     origo: $("#origo")
#     circle: $("#circle")
#
#   #
#   # Handle zooms
#
#   queueZoom = (targetID = null, zoomType = "normal") ->
#     console.log "------------------------------------------------"
#     console.log "QUEUING (#{window.Engine.canvas.queue("fx").length}) #{targetID}"
#
#     # Speed up transition if the queue is long
#     if window.Engine.canvas.queue("fx").length > 0
#       transitionTime = window.Engine.baseTransitionTime * 0.618
#     else
#       transitionTime = window.Engine.baseTransitionTime
#
#     window.Engine.canvas.queue ->
#       currentZoomable = window.Engine.canvas.find("[data-id='#{window.Engine.currentZoomableID}']")
#       if targetID
#         targetZoomable = window.Engine.canvas.find("[data-id='#{targetID}']")
#
#       switch zoomType
#
#         when "stateless"
#           console.log "STATELESS"
#           zoomToFit( targetZoomable[0], transitionTime, true )
#
#         when "background"
#           console.log "BACKGROUND"
#           zoomToFit( targetZoomable[0], 0, false, true )
#
#         when "refocus"
#           if currentZoomable[0] == window.Engine.initialZoomable[0]
#             console.log "NO NEED TO REFOCUS"
#             window.Engine.canvas.dequeue()
#           else
#             console.log "REFOCUS"
#             zoomToFit( currentZoomable[0], transitionTime * 0.5, true )
#
#         when "out"
#           parentZoomables = currentZoomable.parent().closest(".zoomable")
#           if parentZoomables.length > 0
#             console.log "OUT"
#             zoomToFit( window.Engine.canvas.find("[data-id='#{parentZoomables.data("id")}']")[0], transitionTime )
#           else if currentZoomable[0] == window.Engine.initialZoomable[0]
#             console.log "NO NEED TO ZOOM OUT"
#             window.Engine.canvas.dequeue()
#           else
#             console.log "OUT TO HOME"
#             zoomToFit( window.Engine.initialZoomable[0], transitionTime )
#
#         when "normal"
#           if targetID && targetZoomable.length > 0
#             console.log "TARGET BY ID: #{targetID}"
#             zoomToFit( targetZoomable[0], transitionTime )
#           else
#             console.log "NOT ZOOMING; ID NOT FOUND"
#             window.Engine.canvas.dequeue()
#
#   #
#   # Zoom-to-fit function
#
#   zoomToFit = (target, duration = window.Engine.baseTransitionTime, statelessZoom = false, instaZoom = false) ->
#
#     console.log "------------------------------------------------"
#
#     $target = $(target)
#     targetID = $target.data("id")
#
#     # Calculate current viewport, canvas and target positions
#     viewportWidth  = window.Engine.viewport[0].offsetWidth
#     viewportHeight = window.Engine.viewport[0].offsetHeight
#     canvasRect     = window.Engine.canvas[0].getBoundingClientRect()
#     canvasWidth    = canvasRect.width
#     canvasHeight   = canvasRect.height
#     targetRect     = target.getBoundingClientRect()
#     targetWidth    = targetRect.width  / window.Engine.currentScale
#     targetHeight   = targetRect.height / window.Engine.currentScale
#     targetLeft     = targetRect.left # + document.body.scrollLeft
#     targetTop      = targetRect.top # + document.body.scrollTop
#
#     # Calculate new scale, canvas position and transition time
#     # scale = Math.min( viewportWidth/targetWidth, viewportHeight/targetHeight )
#     scale = viewportWidth/targetWidth
#
#     # Calculate left/top positions
#     targetOffsetX  = viewportWidth  / window.Engine.currentScale * 0.5 - targetWidth  * 0.5
#     # targetOffsetY  = viewportHeight / window.Engine.currentScale * 0.5 - targetHeight * 0.5
#     targetOffsetY  = 0
#
#     if window.Engine.initialZoomable[0] == target
#       x = 0
#       y = 0
#       scale = 1
#     else
#       x = round( (targetLeft / window.Engine.currentScale) * -1 + targetOffsetX + window.Engine.currentX, 2 )
#       y = round( (targetTop  / window.Engine.currentScale) * -1 + targetOffsetY + window.Engine.currentY, 2 )
#     z = 0
#
#     # Set transition duration and weigh it by how far we're transiting
#     scaleChange = Math.abs(window.Engine.currentScale - scale)
#     # biggerCoordinate = Math.max( Math.abs(window.Engine.currentX + x), Math.abs(window.Engine.currentY + y) )
#     durationModifier = 1 + (scaleChange / 30) # + (biggerCoordinate / 1000)
#     transitionTime = duration * durationModifier
#
#     # Set new scale and canvas position
#     canvas = window.Engine.canvas[0];
#
#     canvas.style.webkitTransition =
#     canvas.style.msTransition =
#     canvas.style.transition = "all #{transitionTime}s #{window.Engine.transitionEasing}"
#
#     canvas.style.webkitTransform =
#     canvas.style.msTransform =
#     canvas.style.transform = "scale3d(#{scale}, #{scale}, #{scale}) translate3d(#{x}px, #{y}px, #{z}px)"
#
#     #
#     # Set some classes to help with CSS
#
#     if window.Engine.initialZoomable[0] == target
#       window.Engine.htmlTag.addClass("initial-zoom")
#     else
#       window.Engine.htmlTag.removeClass("initial-zoom")
#
#     $(".current-zoomable").removeClass("current-zoomable")
#     $target.addClass("current-zoomable visited-zoomable")
#
#     #
#     # Set history API stuff
#
#     unless statelessZoom
#       if targetID == window.Engine.initialZoomable.data("id")
#         history.pushState({ "targetID" : window.Engine.initialZoomable.data("id") }, $("html head title").text(), "/")
#         console.log "Clearing hash"
#       else
#         history.pushState({ "targetID" : targetID }, $target.data("title"), targetID)
#         console.log "Setting hash to #{targetID} with #{$target.data("title")}"
#     document.title = $target.data("title")
#
#
#     #
#     # After transition ends
#
#     if instaZoom
#       console.log "NOT WAITING FOR TRANSITIONEND"
#       afterTransition(scale, x, y, $target, false)
#     else
#       window.Engine.canvas.on "transitionend webkitTransitionEnd", (event) ->
#         if event.originalEvent.target == window.Engine.canvas[0]
#           console.log "TRANSITIONEND"
#           afterTransition(scale, x, y, $target)
#
#     #
#     # Debug logs
#     console.log $target
#     console.log "currentScale   : #{window.Engine.currentScale}"
#     console.log "viewportWidth  : #{viewportWidth}  "
#     console.log "viewportHeight : #{viewportHeight} "
#     console.log "canvasWidth    : #{canvasWidth}    "
#     console.log "canvasHeight   : #{canvasHeight}   "
#     console.log "targetWidth    : #{targetWidth}    "
#     console.log "targetHeight   : #{targetHeight}   "
#     console.log "targetLeft     : #{targetLeft}     "
#     console.log "targetTop      : #{targetTop}"
#     console.log "scale          : #{scale}"
#     console.log "transitionTime : #{transitionTime} (#{durationModifier}x, [scaleChange: #{scaleChange}])"
#     console.log "z              : #{z}"
#     console.log "y              : #{y}"
#     console.log "x              : #{x}"
#     console.log "targetOffsetY  : #{targetOffsetY} "
#     console.log "targetOffsetX  : #{targetOffsetX} "
#     console.log "all #{transitionTime}s #{window.Engine.transitionEasing}"
#     console.log "scale3d(#{scale}, #{scale}, #{scale}) translate3d(#{x}px, #{y}px, #{z}px)"
#
#     #
#     # Save variables for next transform
#
#     window.Engine.currentScale = scale
#     window.Engine.currentX = x
#     window.Engine.currentY = y
#     window.Engine.currentZoomableID = targetID
#
#   #
#   # Post-transition stuff
#
#   afterTransition = (scale, x, y, $target, removeEvents = true) ->
#
#     # Replace 3D transforms with 2D ones after transition finishes
#     window.Engine.canvas.css
#       "-webkit-transition": "none"
#       "-moz-transition":    "none"
#       "-o-transition":      "none"
#       "-ms-transition":     "none"
#       "-webkit-transform": "scale(#{scale}) translate(#{x}px, #{y}px)"
#       "-moz-transform":    "scale(#{scale}) translate(#{x}px, #{y}px)"
#       "-o-transform":      "scale(#{scale}) translate(#{x}px, #{y}px)"
#       "-ms-transform":     "scale(#{scale}) translate(#{x}px, #{y}px)"
#       "transform":         "scale(#{scale}) translate(#{x}px, #{y}px)"
#     console.log "TRANSFORM2D scale(#{scale}) translate(#{x}px, #{y}px)"
#
#
#     if removeEvents
#       window.Engine.canvas.off "transitionend webkitTransitionEnd"
#
#     window.Engine.canvas.dequeue()
#
#   #
#   # Anchors on zoomables
#
#   $("body").on "click", window.Engine.zoomableAnchor, (event) ->
#     event.preventDefault()
#     targetID = $(this).attr("href")
#     queueZoom( targetID )
#
#   $("body").on "click", window.Engine.zoomableLink, (event) ->
#     event.preventDefault()
#     targetID = $(this).attr("href")
#     # queueZoom( null, "out" )
#     queueZoom( targetID )
#
#
#   #
#   # Zoom out button
#
#   $("#zoom-out").on "click", (event) ->
#     zoomOut()
#
#   #
#   # Zoom out with ESC
#
#   $(document).on "keyup", (event) ->
#     if event.keyCode == 27
#       zoomOut()
#
#   #
#   # Rezoom on resize
#
#   $(window).resize ->
#     clearTimeout @resizeTO if @resizeTO
#     @resizeTO = setTimeout(->
#       $(this).trigger "resizeEnd"
#     , 618)
#
#   $(window).bind "resizeEnd", ->
#     queueZoom( null, "refocus" )
#
#
#   #
#   # Initial zoom (when not loading the root page)
#
#   unless window.Engine.currentZoomableID == "/"
#     queueZoom( window.Engine.currentZoomableID, "background" )
#
#
#   #
#   # Mousemove moves canvas
#
#   canvasX = 0
#   canvasY = 0
#   viewportWidth  = window.Engine.viewport[0].offsetWidth
#   viewportHeight = window.Engine.viewport[0].offsetHeight
#
#   window.Engine.viewport.on "mousemove", (event) ->
#     canvasWidth  = window.Engine.canvas[0].offsetWidth
#     canvasHeight = window.Engine.canvas[0].offsetHeight
#     newCanvasX = event.pageX / viewportWidth  * canvasWidth  * -0.5
#     newCanvasY = event.pageY / viewportHeight * canvasHeight * -0.5
#     canvasX = newCanvasX
#     canvasY = newCanvasY
#     requestAnimFrame( moveCanvas )
#
#   moveCanvas = ->
#     window.Engine.canvas[0].style.webkitTransform =
#     window.Engine.canvas[0].style.msTransform =
#     window.Engine.canvas[0].style.transform = "translate3d(#{canvasX}px, #{canvasY}px, 0px)"
#     # console.log "Moving canvas to translate3d(#{canvasX}px, #{canvasY}px, 0px)"
#
#   #
#   # Touchmove moves circle
#
#   circleX = 0
#   circleY = 0
#
#   window.Engine.circle.on "touchstart touchmove", (event) ->
#     event.preventDefault()
#     touch = event.originalEvent.targetTouches[0]
#     canvasWidth  = window.Engine.canvas[0].offsetWidth
#     canvasHeight = window.Engine.canvas[0].offsetHeight
#     newCircleX = touch.pageX - viewportWidth  + (viewportWidth  / 2)
#     newCircleY = touch.pageY - viewportHeight + (viewportHeight / 2)
#     newCanvasX = touch.pageX / viewportWidth  * canvasWidth  * -0.5
#     newCanvasY = touch.pageY / viewportHeight * canvasHeight * -0.5
#     circleX = newCircleX
#     circleY = newCircleY
#     canvasX = newCanvasX
#     canvasY = newCanvasY
#     requestAnimFrame( moveCircleAndCanvas )
#
#   moveCircleAndCanvas = ->
#     moveCircle()
#     moveCanvas()
#
#   moveCircle = ->
#     window.Engine.circle[0].style.webkitTransform =
#     window.Engine.circle[0].style.msTransform =
#     window.Engine.circle[0].style.transform = "translate3d(#{circleX}px, #{circleY}px, 0px)"
#
#   #
#   # Hide and disable circle on mousemove
#
#   window.Engine.canvas.on "mousemove", (event) ->
#     window.Engine.htmlTag.addClass("mouse-mode")
#     setTimeout ->
#       window.Engine.origo[0].style.display = "none"
#     , window.Engine.baseTransitionTime * 1000
#     window.Engine.canvas.off "mousemove"
#     window.Engine.circle.off "touchstart touchmove"
