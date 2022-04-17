import jester

proc serve*(match: proc, port: Port) =
  let settings = newSettings(port=port)
  var jester = initJester(match, settings=settings)
  jester.serve()