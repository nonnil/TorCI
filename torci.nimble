# Package

version       = "0.1.1"
author        = "Luca"
description   = "Torbox's web based control panel."
license       = "MIT"
srcDir        = "src"
bin           = @["torci"]

skipDirs = @["tests"]

# Dependencies 
requires "nim >= 1.4.0"
requires "jester >= 0.5.0"
requires "karax"
#requires "shell >= 0.4.3"
requires "sass"
requires "hmac"
requires "libcurl >= 1.0.0"
requires "nimpy >= 0.1.1"

task scss, "Generate css":
  exec "nim r tools/gencss"
