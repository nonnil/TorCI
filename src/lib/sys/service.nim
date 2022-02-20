import std / [
  osproc,
  strformat
]

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
