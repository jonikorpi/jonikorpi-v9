#= require_tree .

$ ->
  #
  # Javascript srsly

  round = (value, decimals) ->
    Number Math.round(value + "e" + decimals) + "e-" + decimals

  #
  # Config

  viewport = $("body")
  canvas = $(".site-canvas")
  targetCanvas = $(".target-canvas")
  initialZoomable = $(".initial-zoomable")
  zoomableAnchor = $(".zoomable-anchor")
  zoomableContentClass = ".card-content"

  baseTransitionTime = 0.333
  transitionEasing = "ease-out"

  #
  # Zoom-to-fit function

  zoomToFit = (target, duration = baseTransitionTime, setHash = true) ->

    console.log "------------------------------------------------"

    # Pop .current-zoomable back into canvas, if it's outside
    targetCanvasContent = targetCanvas.find(zoomableContentClass)
    if targetCanvasContent.length > 0
      $(".current-zoomable").children(zoomableContentClass).replaceWith( targetCanvasContent )
      console.log "#{targetCanvasContent} was appended back to #{$(".current-zoomable")}"
    targetCanvas.hide()

    # Fetch previous transform variables, if they exist
    if canvas.data("scale")
      currentScale = canvas.data("scale")
    else
      currentScale = 1

    if canvas.data("x")
      currentX = canvas.data("x")
    else
      currentX = 0

    if canvas.data("y")
      currentY = canvas.data("y")
    else
      currentY = 0

    # Pause any currently running transitions by giving canvas its own current transform values
    # currentCanvasStyles = window.getComputedStyle(canvas[0])
    # realCurrentTransform = currentCanvasStyles.getPropertyValue("-webkit-transform") || currentCanvasStyles.getPropertyValue("-moz-transform") || currentCanvasStyles.getPropertyValue("-o-transform") || currentCanvasStyles.getPropertyValue("-ms-transform") || currentCanvasStyles.getPropertyValue("transform")
    # canvas.css
    #   "-webkit-transition": "none"
    #   "-moz-transition":    "none"
    #   "-o-transition":      "none"
    #   "-ms-transition":     "none"
    #   "transition":         "none"
    #   "-webkit-transform": realCurrentTransform
    #   "-moz-transform":    realCurrentTransform
    #   "-o-transform":      realCurrentTransform
    #   "-ms-transform":     realCurrentTransform
    #   "transform":         realCurrentTransform

    # Calculate current viewport, canvas and target positions
    viewportWidth  = viewport.width()
    viewportHeight = viewport.height()
    canvasWidth    = canvas.width()       # / currentScale
    canvasHeight   = canvas.height()      # / currentScale
    targetWidth    = target.width()       # / currentScale
    targetHeight   = target.height()      # / currentScale
    targetLeft     = target.position().left # / currentScale
    targetTop      = target.position().top  # / currentScale

    # Calculate new scale, canvas position and transition time
    scale = Math.min( viewportWidth/targetWidth, viewportHeight/targetHeight )

    # Calculate left/top positions
    targetOffsetX  = 0#(viewportWidth  - (targetWidth)  ) * 0.5
    targetOffsetY  = 0#(viewportHeight - (targetHeight) ) * 0.5
    if initialZoomable[0] == target[0]
      console.log "initialZoomable is target."
      x = 0
      y = 0
    else
      x = round( (targetLeft / currentScale) * -1, 2 )
      y = round( (targetTop  / currentScale) * -1, 2 )
    z = 0
    transitionTime = duration

    # Set new scale and canvas position
    canvas.css
      "-webkit-transition": "all #{transitionTime}s #{transitionEasing}"
      "-moz-transition":    "all #{transitionTime}s #{transitionEasing}"
      "-o-transition":      "all #{transitionTime}s #{transitionEasing}"
      "-ms-transition":     "all #{transitionTime}s #{transitionEasing}"
      "transition":         "all #{transitionTime}s #{transitionEasing}"
      "-webkit-transform": "scale3d(#{scale}, #{scale}, #{scale}) translate3d(#{x}px, #{y}px, #{z}px)"
      "-moz-transform":    "scale3d(#{scale}, #{scale}, #{scale}) translate3d(#{x}px, #{y}px, #{z}px)"
      "-o-transform":      "scale3d(#{scale}, #{scale}, #{scale}) translate3d(#{x}px, #{y}px, #{z}px)"
      "-ms-transform":     "scale3d(#{scale}, #{scale}, #{scale}) translate3d(#{x}px, #{y}px, #{z}px)"
      "transform":         "scale3d(#{scale}, #{scale}, #{scale}) translate3d(#{x}px, #{y}px, #{z}px)"

    console.log target
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
    console.log "all #{transitionTime}s #{transitionEasing}"
    console.log "scale3d(#{scale}, #{scale}, #{scale}) translate3d(#{x}px, #{y}px, #{z}px)"

    # Set .current-zoomable
    unless $(".current-zoomable")[0] == target
      $(".current-zoomable").removeClass("current-zoomable")
      target.addClass("current-zoomable")

    # Pop target out of the canvas and show it at 1:1 scale
    unless initialZoomable[0] == target[0]
      target.children(zoomableContentClass).clone().appendTo(targetCanvas)
      console.log "#{target.find(zoomableContentClass)} is being appended to #{targetCanvas}"
      canvas.one "transitionend webkitTransitionEnd oTransitionEnd", (event) ->
        targetCanvas.show()
        canvas.off "transitionend webkitTransitionEnd oTransitionEnd"

    # Save transform variables for next transform
    canvas.data("scale", scale)
    canvas.data("x", x)
    canvas.data("y", y)

    # If zoomable has an ID, set it as the URL hash
    if setHash
      targetID = target.attr("id")
      if targetID
        history.pushState("", document.title, targetID)
        # window.location.hash = targetID
        console.log "Setting hash to #{targetID}"
      else
        history.pushState("", document.title, "/")
        # window.location.hash = ""
        console.log "Clearing hash"
    else
      console.log "Not setting a hash"

  #
  # Anchors on zoomables

  zoomableAnchor.on "click", (event) ->
    event.preventDefault()
    zoomToFit( $(this).closest(".zoomable") )

  #
  # Zoom out button

  $("#zoom-out").on "click", (event) ->
    if initialZoomable.hasClass("current-zoomable")
      zoomToFit( initialZoomable )
    else
      if $(".current-zoomable").parent().closest(".zoomable").length > 0
        zoomToFit( $(".current-zoomable").parent().closest(".zoomable") )
      else
        zoomToFit( initialZoomable )

  #
  # Zoom out with ESC

  $(document).on "keyup", (event) ->
    if event.keyCode == 27
      $("#zoom-out").click()

  #
  # Rezoom on resize

  $(window).resize ->
    clearTimeout @resizeTO if @resizeTO
    @resizeTO = setTimeout(->
      $(this).trigger "resizeEnd"
    , 618)

  $(window).bind "resizeEnd", ->
    console.log "------------------------------------------------"
    console.log "Transforming again due to window resizing!"
    zoomToFit( $(".current-zoomable") )

  #
  # Init

  # Initial zoom
  initialHash = window.location.hash.substr(1)
  if initialHash
    zoomToFit( $("##{initialHash}"), 0, false )
  else
    zoomToFit( initialZoomable )
