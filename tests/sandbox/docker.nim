import std / [
  os, osproc, terminal,
  strutils
]

const
  atme = "tests" / "sandbox"
  # dockerFile = "Dockerfile"

# proc imageExists(label: string): bool =
#   const prefix = "sudo docker images "

#   let res = execCmdEx(prefix & label)

#   for line in splitLines(res.output):
#     proc(x: string): bool: startsWith

func build(imageLabel: string = ""): int =
  const prefix = "sudo docker build"

  let
    label = if imageLabel.len == 0: " -t torci:test"
      else: " -t " & imageLabel

    path = "-f "
    cm = prefix & label & path
    
  # sudo docker build -t {{ a label }} -f tests/docker/Dockerfile
  result = execCmd(cm & atme)

proc run(imageLabel: string = ""): Process =
  const prefix = "sudo docker run --rm -v `pwd`:/src/torci"

  let
    label = if imageLabel.len == 0: " torci:test"
      else: imageLabel

    cm = prefix & label

  result = startProcess(cm)

when isMainModule:
  let code = build()

  if code != 0:
    styledEcho fgRed, "[Docker build] ", fgWhite, "failure."
    quit()

  styledEcho fgGreen, "[Docker build] ", fgWhite, "build successfully."

  let process = run()

  styledEcho fgGreen, "[Ok] ", fgWhite, "tests successfully in Docker container."

  kill process