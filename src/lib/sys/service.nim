import std / [
  osproc,
  asyncdispatch,
  strformat, strutils
]

proc isActiveService*(service: string): Future[bool] {.async.} =
  try:
    if service.len >= 0 and
    service.contains(IdentChars):
      let cmd = fmt("systemctl is-active \"{service}\"")
      let
        ret = execCmdEx(cmd)
        sta = ret.output.splitLines()[0]
      if sta == "active":
        return true
  except OSError: return false
  except IOError: return false
  except ValueError: return false
  except KeyError: return false
  except CatchableError: return false
  except: return false

proc startService*(s: string) =
  const cmd = "sudo systemctl start "
  discard execCmd(cmd & &"\"{s}\"")
  
proc stopService*(s: string) =
  const cmd = "sudo systemctl stop "
  discard execCmd(cmd & &"\"{s}\"")
  discard execCmd("sudo systemctl daemon-reload")

proc restartService*(s: string) =
  const cmd = "sudo systemctl restart "
  discard execCmd(cmd & &"\"{s}\"")
