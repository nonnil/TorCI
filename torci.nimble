# Package

version       = "0.1.3"
author        = "Luca"
description   = "Configuration Interface for TorBox."
license       = "GPL-3.0"
srcDir        = "src"
bin           = @["torci"]

skipDirs = @["tests"]

# Dependencies 
requires "nim >= 1.4.0"
requires "jester >= 0.5.0"
requires "karax >= 1.2.1"
requires "sass"
requires "libcurl >= 1.0.0"
requires "bcrypt >= 0.2.1"
requires "result >= 0.3.0"

task scss, "Generate css":
  exec "nim r tools/gencss"

task tests, "Run tests":
  exec "nimble -d:test test -y"