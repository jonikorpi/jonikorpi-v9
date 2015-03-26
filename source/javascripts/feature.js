
/**
 * Function that takes a standard CSS property name as a parameter and
 * returns it's prefixed version valid for current browser it runs in
 */
var pfx = (function() {
  var style = document.createElement("dummy").style,
    prefixes = "Webkit Moz O ms Khtml".split(" "),
    memory = {};
  return function(prop) {
    if (typeof memory[prop] === "undefined") {
      var ucProp = prop.charAt(0).toUpperCase() + prop.substr(1),
        props = (prop + " " + prefixes.join(ucProp + " ") + ucProp).split(" ");
        memory[prop] = null;
      for (var i in props) {
        if (style[props[i]] !== undefined) {
          memory[prop] = props[i];
          break;
        }
      }
    }
    return memory[prop];
  };
})();


/**
 * Feature tests
 */
var feature = {

  // Test if 3D transforms are supported
  css3Dtransforms : !!(pfx("perspective") !== null),

  // Test if History API is supported
  historyAPI : !!history.pushState,

  // Test if viewport units are supported
  viewportUnits : (function(el) {
    el.style.width = "100vw";
    return !!(el.style.width !== "");
  })(document.createElement("dummy"))

};
