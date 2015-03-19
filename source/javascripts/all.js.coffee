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
  zoomableAnchor = ".zoomable-anchor"

  baseTransitionTime = 0.382
  transitionEasing = "ease-out"

  #
  # Zoom-to-fit function

  zoomToFit = (target, duration = baseTransitionTime, setHash = true) ->

    console.log "------------------------------------------------"

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

    # Calculate current viewport, canvas and target positions
    viewportWidth  = viewport.width()
    viewportHeight = viewport.height()
    canvasWidth    = canvas[0].getBoundingClientRect().width
    canvasHeight   = canvas[0].getBoundingClientRect().height
    targetWidth    = target[0].getBoundingClientRect().width  / currentScale
    targetHeight   = target[0].getBoundingClientRect().height / currentScale
    targetLeft     = target.offset().left
    targetTop      = target.offset().top

    # Calculate new scale, canvas position and transition time
    scale = Math.min( viewportWidth/targetWidth, viewportHeight/targetHeight )

    # Calculate left/top positions
    targetOffsetX  = viewportWidth  / currentScale * 0.5 - targetWidth  * 0.5
    targetOffsetY  = viewportHeight / currentScale * 0.5 - targetHeight * 0.5
    if initialZoomable[0] == target[0]
      console.log "initialZoomable is target."
      x = 0
      y = 0
    else
      x = round( (targetLeft / currentScale) * -1 + targetOffsetX + currentX, 2 )
      y = round( (targetTop  / currentScale) * -1 + targetOffsetY + currentY, 2 )
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

    # Replace 3D transforms with 2D ones after transition finishes
    canvas.one "otransitionend transitionend webkitTransitionEnd", (event) ->
      canvas.off "otransitionend transitionend webkitTransitionEnd"
      canvas.css
        "-webkit-transition": "none"
        "-moz-transition":    "none"
        "-o-transition":      "none"
        "-ms-transition":     "none"
        "-webkit-transform": "scale(#{scale}) translate(#{x}px, #{y}px)"
        "-moz-transform":    "scale(#{scale}) translate(#{x}px, #{y}px)"
        "-o-transform":      "scale(#{scale}) translate(#{x}px, #{y}px)"
        "-ms-transform":     "scale(#{scale}) translate(#{x}px, #{y}px)"
        "transform":         "scale(#{scale}) translate(#{x}px, #{y}px)"
      console.log "Now setting scale(#{scale}) translate(#{x}px, #{y}px)"

    console.log target
    console.log "currentScale   : #{currentScale}"
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

    # Pop .current-zoomable back into canvas, if it's outside
    # targetCanvasContent = targetCanvas.children()
    # if targetCanvasContent.length > 0
    #   $(".current-zoomable").replaceWith( targetCanvasContent[0] )
    #   console.log "#{targetCanvasContent[0]} was appended back to #{$(".current-zoomable")}"
    # targetCanvas.hide()

    # Pop target out of the canvas and show it at 1:1 scale
    # unless initialZoomable[0] == target[0]
    #   target.clone().appendTo(targetCanvas)
    #   console.log "#{target.children()} is being appended to #{targetCanvas}"
    #   canvas.one "transitionend webkitTransitionEnd oTransitionEnd", (event) ->
    #     targetCanvas.show()
    #     canvas.off "transitionend webkitTransitionEnd oTransitionEnd"

    # Set new .current-zoomable
    unless $(".current-zoomable")[0] == target
      $(".current-zoomable").removeClass("current-zoomable")
      target.addClass("current-zoomable")
      if target.hasClass("initial-zoomable")
        $("html").addClass("initial-zoom")
      else
        $("html").removeClass("initial-zoom")

    # Save transform variables for next transform
    canvas.data("scale", scale)
    canvas.data("x", x)
    canvas.data("y", y)

    # If zoomable has an ID, set it as the URL hash
    # if setHash
    #   targetID = target.attr("id")
    #   if targetID
    #     history.pushState("", document.title, targetID)
    #     # window.location.hash = targetID
    #     console.log "Setting hash to #{targetID}"
    #   else
    #     history.pushState("", document.title, "/")
    #     # window.location.hash = ""
    #     console.log "Clearing hash"
    # else
    #   console.log "Not setting a hash"

  #
  # Anchors on zoomables

  $("body").on "click", zoomableAnchor, (event) ->
    event.preventDefault()
    zoomToFit( $(this).closest(".zoomable") )

  #
  # Zoom out button

  $("#zoom-out").on "click", (event) ->
    unless initialZoomable.hasClass("current-zoomable")
      parentZoomables = $(".current-zoomable").parent().closest(".zoomable")
      console.log "------------------------------------------------"
      if parentZoomables.length > 0
        console.log "Zooming out to:"
        console.log parentZoomables[0]
        zoomToFit( $(parentZoomables[0]) )
      else
        console.log "Zooming out to initialZoomable"
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
  # initialHash = window.location.hash.substr(1)
  # if initialHash
  #   zoomToFit( $("##{initialHash}"), 0, false )
  # else
  #   zoomToFit( initialZoomable )
