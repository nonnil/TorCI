import std / [ os, osproc ]

proc compile*(path: string): int =
  const prefix = "nim c "
  execCmd(prefix & path)

template start*(name: string): Process =
  let path = "tests" / "server" / "routes" / name

  if not fileExists(path):
    let code = compile(path)
    if code != 0:
      raise newException(IOError, "Can't compile " & path)

  startProcess(expandFilename(path))

when isMainModule:
  let pro = start("status")