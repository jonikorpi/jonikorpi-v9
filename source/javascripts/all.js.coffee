#= require_tree .

$ ->
  #
  # Javascript srsly

  # Feature tests
  console.log("Viewport Units supported? " + feature.viewportUnits)
  console.log("History API supported? " + feature.historyAPI)
  console.log("CSS 3D transforms supported? " + feature.css3Dtransforms)

  if !feature.viewportUnits || !feature.historyAPI || !feature.css3Dtransforms
    console.log("Browser doesn't support one of the features needed, stopping…")
    return
  else
    $("html").addClass("awesome")

  round = (value, decimals) ->
    Number Math.round(value + "e" + decimals) + "e-" + decimals

  #
  # Config

  window.Engine =
    htmlTag: $("html")
    viewport: $("body")
    canvas: $(".site-canvas")
    targetCanvas: $(".target-canvas")
    initialZoomable: $(".initial-zoomable")
    zoomableAnchor: ".zoomable-anchor"
    zoomableLink: ".zoomable-link"
    zoomOutButton: $("#zoom-out")
    baseTransitionTime: 0.414
    transitionEasing: "cubic-bezier(0.236, 0, 0.146, 1.236)"
    currentScale: 1
    currentX: 0
    currentY: 0
    currentZoomableID: $("html").data("current-zoomable")

  #
  # Handle zooms

  queueZoom = (targetID = null, zoomType = "normal") ->
    console.log "------------------------------------------------"
    console.log "QUEUING (#{window.Engine.canvas.queue("fx").length}) #{targetID}"

    if window.Engine.canvas.queue("fx").length > 0
      transitionTime = window.Engine.baseTransitionTime * 0.854
    else
      transitionTime = window.Engine.baseTransitionTime

    window.Engine.canvas.queue ->
      currentZoomable = window.Engine.canvas.find("[data-id='#{window.Engine.currentZoomableID}']")
      parentZoomables = currentZoomable.parent().closest(".zoomable")
      if targetID
        targetZoomable = window.Engine.canvas.find("[data-id='#{targetID}']")

      switch zoomType
        when "stateless"
          console.log "STATELESS"
          zoomToFit( targetZoomable[0], transitionTime, false, true )
        when "background"
          console.log "BACKGROUND"
          zoomToFit( targetZoomable[0], 0, true )
        when "refocus"
          if currentZoomable[0] == window.Engine.initialZoomable[0]
            console.log "NO NEED TO REFOCUS"
            window.Engine.canvas.dequeue()
          else
            console.log "REFOCUS"
            zoomToFit( currentZoomable[0], transitionTime * 0.854, true )
        when "out"
          if parentZoomables.length > 0
            console.log "OUT"
            zoomToFit( window.Engine.canvas.find("[data-id='#{parentZoomables.data("id")}']")[0], transitionTime )
          else if currentZoomable[0] == window.Engine.initialZoomable[0]
            console.log "NO NEED TO ZOOM OUT"
            window.Engine.canvas.dequeue()
          else
            console.log "OUT TO HOME"
            zoomToFit( window.Engine.initialZoomable[0], transitionTime )
        when "normal"
          if targetID && targetZoomable.length > 0
            console.log "TARGET BY ID: #{targetID}"
            zoomToFit( targetZoomable[0], transitionTime )
          else
            console.log "TARGET HOME"
            zoomToFit( window.Engine.initialZoomable[0], transitionTime )

  #
  # Zoom-to-fit function

  zoomToFit = (target, duration = window.Engine.baseTransitionTime, backgroundZoom = false, statelessZoom = false) ->

    console.log "------------------------------------------------"

    $target = $(target)
    targetID = $target.data("id")

    #
    # Pop .current-zoomable back into canvas, if it's outside

    unless backgroundZoom
      console.log "HIDING TARGET CANVAS"
      window.Engine.targetCanvas[0].style.display = "none"
      targetCanvasContent = window.Engine.targetCanvas.children(".zoomable")
      if targetCanvasContent.length > 0
        # window.Engine.canvas.find(".target-placeholder").replaceWith( targetCanvasContent[0] )
        # console.log targetCanvasContent[0]
        # console.log "… was appended back."
        window.Engine.targetCanvas[0].innerHTML = ""

    # Calculate current viewport, canvas and target positions
    viewportWidth  = window.Engine.viewport[0].offsetWidth
    viewportHeight = window.Engine.viewport[0].offsetHeight
    canvasRect     = window.Engine.canvas[0].getBoundingClientRect()
    canvasWidth    = canvasRect.width
    canvasHeight   = canvasRect.height
    targetRect     = target.getBoundingClientRect()
    targetWidth    = targetRect.width  / window.Engine.currentScale
    targetHeight   = targetRect.height / window.Engine.currentScale
    targetLeft     = targetRect.left # + document.body.scrollLeft
    targetTop      = targetRect.top # + document.body.scrollTop

    # Calculate new scale, canvas position and transition time
    scale = Math.min( viewportWidth/targetWidth, viewportHeight/targetHeight )

    # Calculate left/top positions
    targetOffsetX  = viewportWidth  / window.Engine.currentScale * 0.5 - targetWidth  * 0.5
    targetOffsetY  = viewportHeight / window.Engine.currentScale * 0.5 - targetHeight * 0.5

    if window.Engine.initialZoomable[0] == target
      x = 0
      y = 0
      scale = 1
    else
      x = round( (targetLeft / window.Engine.currentScale) * -1 + targetOffsetX + window.Engine.currentX, 5 )
      y = round( (targetTop  / window.Engine.currentScale) * -1 + targetOffsetY + window.Engine.currentY, 5 )
    z = 0

    # Set transition duration and weigh it by how far we're transiting
    scaleChange = Math.abs(window.Engine.currentScale - scale)
    biggerCoordinate = Math.max( Math.abs(window.Engine.currentX + x), Math.abs(window.Engine.currentY + y) )
    durationModifier = 1 + biggerCoordinate / 900 + scaleChange / 50
    transitionTime = duration * durationModifier

    # Set new scale and canvas position
    canvas = window.Engine.canvas[0];

    canvas.style.webkitTransition =
    canvas.style.msTransition =
    canvas.style.transition = "all #{transitionTime}s #{window.Engine.transitionEasing}"

    canvas.style.webkitTransform =
    canvas.style.msTransform =
    canvas.style.transform = "scale3d(#{scale}, #{scale}, #{scale}) translate3d(#{x}px, #{y}px, #{z}px)"

    #
    # Debug logs
    console.log $target
    console.log "currentScale   : #{window.Engine.currentScale}"
    console.log "viewportWidth  : #{viewportWidth}  "
    console.log "viewportHeight : #{viewportHeight} "
    console.log "canvasWidth    : #{canvasWidth}    "
    console.log "canvasHeight   : #{canvasHeight}   "
    console.log "targetWidth    : #{targetWidth}    "
    console.log "targetHeight   : #{targetHeight}   "
    console.log "targetLeft     : #{targetLeft}     "
    console.log "targetTop      : #{targetTop}"
    console.log "scale          : #{scale}"
    console.log "transitionTime : #{transitionTime}"
    console.log "z              : #{z}"
    console.log "y              : #{y}"
    console.log "x              : #{x}"
    console.log "targetOffsetY  : #{targetOffsetY} "
    console.log "targetOffsetX  : #{targetOffsetX} "
    console.log "all #{transitionTime}s #{window.Engine.transitionEasing}"
    console.log "scale3d(#{scale}, #{scale}, #{scale}) translate3d(#{x}px, #{y}px, #{z}px)"

    #
    # Set some classes to help with CSS

    if window.Engine.initialZoomable[0] == target
      window.Engine.htmlTag.addClass("initial-zoom")
    else
      window.Engine.htmlTag.removeClass("initial-zoom")

    $(".current-zoomable").removeClass("current-zoomable")
    $target.addClass("current-zoomable")

    #
    # Save variables for next transform

    window.Engine.currentScale = scale
    window.Engine.currentX = x
    window.Engine.currentY = y
    window.Engine.currentZoomableID = targetID

    #
    # Set history API stuff

    unless statelessZoom
      if targetID == window.Engine.initialZoomable.data("id")
        history.pushState({ "targetID" : window.Engine.initialZoomable.data("id") }, $("html head title").text(), "/")
        console.log "Clearing hash"
      else
        history.pushState({ "targetID" : targetID }, $target.data("title"), targetID)
        console.log "Setting hash to #{targetID} with #{$target.data("title")}"
    document.title = $target.data("title")

    #
    # After transition ends

    if backgroundZoom
      console.log "NOT WAITING FOR TRANSITION TO END"
      window.Engine.canvas.dequeue()
    else
      window.Engine.canvas.one "transitionend webkitTransitionEnd", (event) ->
        console.log "TRANSITIONEND"

        # Replace 3D transforms with 2D ones after transition finishes
        # window.Engine.canvas.off "otransitionend transitionend webkitTransitionEnd"
        # window.Engine.canvas.css
        #   "-webkit-transition": "none"
        #   "-moz-transition":    "none"
        #   "-o-transition":      "none"
        #   "-ms-transition":     "none"
        #   "-webkit-transform": "scale(#{scale}) translate(#{x}px, #{y}px)"
        #   "-moz-transform":    "scale(#{scale}) translate(#{x}px, #{y}px)"
        #   "-o-transform":      "scale(#{scale}) translate(#{x}px, #{y}px)"
        #   "-ms-transform":     "scale(#{scale}) translate(#{x}px, #{y}px)"
        #   "transform":         "scale(#{scale}) translate(#{x}px, #{y}px)"
        # console.log "Now setting scale(#{scale}) translate(#{x}px, #{y}px)"

        # Pop target out of the canvas and show it at 1:1 scale
        unless window.Engine.initialZoomable[0] == target
          console.log "SHOWING TARGET CANVAS"
          window.Engine.targetCanvas[0].style.display = "block"
          $target.clone().appendTo(window.Engine.targetCanvas)

        window.Engine.canvas.off "transitionend webkitTransitionEnd"
        window.Engine.canvas.dequeue()

  #
  # Anchors on zoomables

  $("body").on "click", window.Engine.zoomableAnchor, (event) ->
    event.preventDefault()
    targetID = $(this).attr("href")
    queueZoom( targetID )

  $("body").on "click", window.Engine.zoomableLink, (event) ->
    event.preventDefault()
    targetID = $(this).attr("href")
    # queueZoom( null, "out" )
    queueZoom( targetID )

  #
  # Zoom out

  zoomOut = ->
    queueZoom( null, "out" )

  #
  # Zoom out button

  $("#zoom-out").on "click", (event) ->
    zoomOut()

  #
  # Zoom out with ESC

  $(document).on "keyup", (event) ->
    if event.keyCode == 27
      zoomOut()

  #
  # Rezoom on resize

  $(window).resize ->
    clearTimeout @resizeTO if @resizeTO
    @resizeTO = setTimeout(->
      $(this).trigger "resizeEnd"
    , 618)

  $(window).bind "resizeEnd", ->
    queueZoom( null, "refocus" )

  #
  # Support history state changes

  history.replaceState({ "targetID" : window.Engine.currentZoomableID }, document.title, window.Engine.currentZoomableID)

  $(window).on "popstate", (event) ->
    console.log "POPSTATE"
    if event.originalEvent.state && event.originalEvent.state.targetID
      console.log "POPSTATE TARGETID: #{event.originalEvent.state.targetID}"
      queueZoom( event.originalEvent.state.targetID, "stateless" )

  #
  # Initial zoom (when not loading the root page)

  unless window.Engine.currentZoomableID == "/"
    queueZoom( window.Engine.currentZoomableID, "background" )
