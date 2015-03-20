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
  # Set hash and history API functions

  setHash = (target) ->
    # targetID = target.attr("id")
    # if targetID
    #   history.pushState("", document.title, targetID)
    #   # window.location.hash = targetID
    #   console.log "Setting hash to #{targetID}"
    # else
    #   history.pushState("", document.title, "/")
    #   # window.location.hash = ""
    #   console.log "Clearing hash"

  #
  # Pop .current-zoomable back into canvas, if it's outside

  returnTarget = (target) ->
    targetCanvas.hide()
    targetCanvasContent = targetCanvas.children(".zoomable")
    if targetCanvasContent.length > 0
      $(".target-placeholder").replaceWith( targetCanvasContent[0] )
      console.log "#{targetCanvasContent[0]} was appended back to replace #{$(".current-zoomable")}"

  #
  # Set new .current-zoomable

  setCurrentZoomable = (target) ->
    unless $(".current-zoomable")[0] == target
      $(".current-zoomable").removeClass("current-zoomable")
      target.addClass("current-zoomable")
      if target.hasClass("initial-zoomable")
        $("html").addClass("initial-zoom")
      else
        $("html").removeClass("initial-zoom")

  #
  # Pop target out of the canvas and show it at 1:1 scale

  cloneTarget = (target) ->
    unless initialZoomable[0] == target[0]
      console.log "#{target} is being appended to #{targetCanvas}"
      canvas.one "transitionend webkitTransitionEnd oTransitionEnd", (event) ->
        targetCanvas.show()
        target.clone().appendTo(targetCanvas)
        target.replaceWith("<div class='zoomable target-placeholder'></div>")
        canvas.off "transitionend webkitTransitionEnd oTransitionEnd"

  #
  # Zoom-to-fit function

  zoomToFit = (target, duration = baseTransitionTime) ->

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
      scale = 1
    else
      x = round( (targetLeft / currentScale) * -1 + targetOffsetX + currentX, 5 )
      y = round( (targetTop  / currentScale) * -1 + targetOffsetY + currentY, 5 )

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

    # Save transform variables for next transform
    canvas.data("scale", scale)
    canvas.data("x", x)
    canvas.data("y", y)

  #
  # Anchors on zoomables

  $("body").on "click", zoomableAnchor, (event) ->
    event.preventDefault()
    target = $(this).closest(".zoomable")
    zoomToFit(target)
    setHash(target)
    returnTarget(target)
    setCurrentZoomable(target)
    cloneTarget(target)

  #
  # Zoom out button

  $("#zoom-out").on "click", (event) ->
    unless initialZoomable.hasClass("current-zoomable")
      parentZoomables = $(".target-placeholder").parent().closest(".zoomable")
      console.log "------------------------------------------------"
      if parentZoomables.length > 0
        console.log "Zooming out to:"
        console.log parentZoomables[0]
        target = $(parentZoomables[0])
      else
        console.log "Zooming out to initialZoomable"
        target = initialZoomable
      zoomToFit(target)
      setHash(target)
      returnTarget(target)
      setCurrentZoomable(target)
      cloneTarget(target)

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
    targetPlaceholder = $(".target-placeholder")
    if targetPlaceholder.length > 0
      zoomToFit( targetPlaceholder )
      console.log "------------------------------------------------"
      console.log "Transforming again due to window resizing!"

  #
  # Init

  # Initial zoom
  # initialHash = window.location.hash.substr(1)
  # if initialHash
  #   zoomToFit( $("##{initialHash}"), 0, false )
  # else
  #   zoomToFit( initialZoomable )
