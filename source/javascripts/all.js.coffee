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

  round = (value, decimals) ->
    Number Math.round(value + "e" + decimals) + "e-" + decimals

  #
  # Config

  window.Engine =
    htmlTag: $("html")
    viewport: $(".site-viewport")
    canvas: $(".site-canvas")
    targetCanvas: $(".target-canvas")
    initialZoomable: $(".initial-zoomable")
    zoomableAnchor: ".zoomable-anchor"
    zoomableLink: ".zoomable-content a[href^='/']"
    baseTransitionTime: 0.382
    transitionEasing: "ease-out"
    currentScale: 1
    currentX: 0
    currentY: 0
    currentZoomableId: $("html").data("current-zoomable")

  #
  # Handle zooms

  handleStatelessZoom = (targetID) ->
    zoomToFit( window.Engine.canvas.find("[data-id='#{targetID}']"), window.Engine.baseTransitionTime, false, true )

  handleBackgroundZoom = (targetID) ->
    zoomToFit( window.Engine.canvas.find("[data-id='#{targetID}']"), 0, true )

  handleZoom = (targetID) ->
    console.log "Handling #{targetID}"

    if targetID == "refocus"
      # Target the same element
      console.log "TARGET THE SAME ELEMENT"
      targetPlaceholder = $(".target-placeholder")
      if targetPlaceholder.length > 0
        zoomToFit( window.Engine.canvas.find("##{targetPlaceholder.data("id")}") )
      else
        unless window.Engine.htmlTag.hasClass("initial-zoom")
          zoomToFit( window.Engine.initialZoomable )
        else
          window.Engine.canvas.dequeue()

    else if targetID == "out"
      # Target parent zoomable
      console.log "TARGET PARENT ZOOMABLE"
      parentZoomables = window.Engine.canvas.find(".current-zoomable").parent().closest(".zoomable")
      if parentZoomables.length > 0
        zoomToFit( window.Engine.canvas.find("##{parentZoomables.data("id")}") )
      else
        unless window.Engine.htmlTag.hasClass("initial-zoom")
          zoomToFit( window.Engine.initialZoomable )
        else
          window.Engine.canvas.dequeue()

    else if window.Engine.canvas.find("[data-id='#{targetID}']").length > 0
      # Target by ID
      console.log "TARGET BY ID: #{targetID}"
      zoomToFit( window.Engine.canvas.find("[data-id='#{targetID}']") )

    else
      # Target home
      console.log "TARGET HOME"
      unless window.Engine.htmlTag.hasClass("initial-zoom")
        zoomToFit( window.Engine.initialZoomable )
      else
        window.Engine.canvas.dequeue()

  #
  # Zoom-to-fit function

  zoomToFit = (target, duration = window.Engine.baseTransitionTime, backgroundZoom = false, statelessZoom = false) ->

    console.log "------------------------------------------------"

    targetID = target.data("id")

    #
    # Pop .current-zoomable back into canvas, if it's outside
    unless backgroundZoom
      window.Engine.targetCanvas.hide()
      targetCanvasContent = window.Engine.targetCanvas.children(".zoomable")
      if targetCanvasContent.length > 0
        # window.Engine.canvas.find(".target-placeholder").replaceWith( targetCanvasContent[0] )
        # console.log targetCanvasContent[0]
        # console.log "… was appended back."
        window.Engine.targetCanvas.html("")

    # Calculate current viewport, canvas and target positions
    viewportWidth  = window.Engine.viewport.width()
    viewportHeight = window.Engine.viewport.height()
    canvasWidth    = window.Engine.canvas[0].getBoundingClientRect().width
    canvasHeight   = window.Engine.canvas[0].getBoundingClientRect().height
    targetWidth    = target[0].getBoundingClientRect().width  / window.Engine.currentScale
    targetHeight   = target[0].getBoundingClientRect().height / window.Engine.currentScale
    targetLeft     = target.offset().left
    targetTop      = target.offset().top

    # Calculate new scale, canvas position and transition time
    scale = Math.min( viewportWidth/targetWidth, viewportHeight/targetHeight )

    # Calculate left/top positions
    targetOffsetX  = viewportWidth  / window.Engine.currentScale * 0.5 - targetWidth  * 0.5
    targetOffsetY  = viewportHeight / window.Engine.currentScale * 0.5 - targetHeight * 0.5

    if window.Engine.initialZoomable[0] == target[0]
      x = 0
      y = 0
      scale = 1
    else
      x = round( (targetLeft / window.Engine.currentScale) * -1 + targetOffsetX + window.Engine.currentX, 5 )
      y = round( (targetTop  / window.Engine.currentScale) * -1 + targetOffsetY + window.Engine.currentY, 5 )

    z = 0
    transitionTime = duration

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
    console.log target
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

    if window.Engine.initialZoomable[0] == target[0]
      window.Engine.htmlTag.addClass("initial-zoom")
    else
      window.Engine.htmlTag.removeClass("initial-zoom")

    $(".current-zoomable").removeClass("current-zoomable")
    target.addClass("current-zoomable")

    #
    # Save variables for next transform

    window.Engine.currentScale = scale
    window.Engine.currentX = x
    window.Engine.currentY = y
    window.Engine.currentZoomableId = targetID

    #
    # Set history API stuff

    unless statelessZoom
      if targetID == window.Engine.initialZoomable.data("id")
        history.pushState({ "targetID" : window.Engine.initialZoomable.data("id") }, $("html head title").text(), "/")
        console.log "Clearing hash"
      else
        history.pushState({ "targetID" : targetID }, target.data("title"), targetID)
        console.log "Setting hash to #{targetID} with #{target.data("title")}"
    document.title = target.data("title")

    #
    # After transition ends

    if backgroundZoom
      window.Engine.canvas.dequeue()
    else
      window.Engine.canvas.one "otransitionend transitionend webkitTransitionEnd", (event) ->

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
        unless window.Engine.initialZoomable[0] == target[0]
          window.Engine.targetCanvas.show()
          target.clone().appendTo(window.Engine.targetCanvas)

        console.log window.Engine.targetCanvas
        window.Engine.canvas.off "transitionend webkitTransitionEnd oTransitionEnd"
        window.Engine.canvas.dequeue()

  #
  # Anchors on zoomables

  $("body").on "click", window.Engine.zoomableAnchor, (event) ->
    event.preventDefault()
    targetID = $(this).attr("href")
    window.Engine.canvas.queue ->
      handleZoom( targetID )

  $("body").on "click", window.Engine.zoomableLink, (event) ->
    event.preventDefault()
    targetID = $(this).attr("href")
    window.Engine.canvas.queue ->
      handleZoom( targetID )

  #
  # Zoom out

  zoomOut = ->
    window.Engine.canvas.queue ->
      handleZoom( "out" )

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
    window.Engine.canvas.queue ->
      handleZoom( "refocus" )

  #
  # Support history state changes

  history.replaceState({ "targetID" : window.Engine.currentZoomableId }, document.title, window.Engine.currentZoomableId)

  $(window).on "popstate", (event) ->
    console.log "POPSTATE"
    if event.originalEvent.state && event.originalEvent.state.targetID
      console.log "POPSTATE TARGETID: #{event.originalEvent.state.targetID}"
      window.Engine.canvas.queue ->
        handleStatelessZoom( event.originalEvent.state.targetID )

  #
  # Initial zoom (when not loading the root page)

  unless window.Engine.currentZoomableId == "/"
    window.Engine.canvas.queue ->
      handleBackgroundZoom( window.Engine.currentZoomableId )
