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
    # targetCanvasContent = targetCanvas.find(zoomableContentClass)
    # if targetCanvasContent.length > 0
    #   targetCanvasContent.appendTo(".current-zoomable")
    #   targetCanvas.hide()
    #   console.log "#{targetCanvasContent} was appended back to #{$(".current-zoomable")}"

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
    canvasWidth    = canvas[0].getBoundingClientRect().width
    canvasHeight   = canvas[0].getBoundingClientRect().height
    targetWidth    = target[0].getBoundingClientRect().width  / currentScale
    targetHeight   = target[0].getBoundingClientRect().height / currentScale
    targetLeft     = target[0].getBoundingClientRect().left
    targetTop      = target[0].getBoundingClientRect().top

    # Calculate new scale, canvas position and transition time
    scale = Math.min( viewportWidth/targetWidth, viewportHeight/targetHeight )

    # Calculate left/top positions
    targetOffsetX  = 0#(viewportWidth  - (targetWidth)  ) * 0.5
    targetOffsetY  = 0#(viewportHeight - (targetHeight) ) * 0.5
    x = round( (targetLeft / currentScale) * -1 + currentX + targetOffsetX, 2 )
    y = round( (targetTop  / currentScale) * -1 + currentY + targetOffsetY, 2 )
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
    console.log "Fitting #{targetWidth}/#{targetHeight} into #{viewportWidth}/#{viewportHeight}"
    console.log "Current transform: [#{currentScale}, #{currentX}px, #{currentY}px]"
    console.log "New transform: [#{scale}, #{x}px, #{y}px]"
    console.log "Offsetting by [#{targetOffsetX}, #{targetOffsetY}]"
    console.log "During #{transitionTime}s with #{transitionEasing}"

    # Set .current-zoomable
    unless $(".current-zoomable")[0] == target
      $(".current-zoomable").removeClass("current-zoomable")
      target.addClass("current-zoomable")

    # Pop target out of the canvas and show it at 1:1 scale
    # target.find(zoomableContentClass).appendTo(targetCanvas)
    # targetCanvas.show()
    # console.log "#{target.find(zoomableContentClass)} was appended to #{targetCanvas}"

    # Save transform variables for next transform
    canvas.data("scale", scale)
    canvas.data("x", x)
    canvas.data("y", y)

    # If zoomable has an ID, set it as the URL hash
    if setHash
      targetID = target.attr("id")
      if targetID
        window.location.hash = targetID
        console.log "Setting hash to #{targetID}"
      else
        window.location.hash = ""
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
