import asyncdispatch, strutils, strformat, re, tables
import os, osproc
import ../types
import wirelessManager

proc parseRoute(str: string): tuple[inputIo, outputIo, tunIo: string] =
  let lines = str.splitLines()
  for v in lines:
    let vv = v.splitwhitespace()
    if vv[0] == "default":
      result.inputIo = vv[7]

proc parseCpuinfo(source, kind: string): string =
  case kind
  of "architecture":
    let lines = source.splitLines
    for v in lines:
      if v.match(re"model name.*"):
        result = v.split(":")[1]
  of "kernelVersion":
    return source.splitWhitespace[2]
  of "model":
    let lines = source.splitLines
    for v in lines:
      if v.match(re"Model.*"):
        result = v.split(":")[1]

proc getSystemInfo*(): SystemInfo = 
  const
    procDir = "/proc"
    procVersion = procDir / "version"
    procCpuinfo = procDir / "cpuinfo"
  # try:
  let
    version = readFile(procVersion)
    cpuinfo = readFile(procCpuinfo)
  result = SystemInfo(
    kernelVersion: version.parseCpuinfo("kernelVersion"),
    model: cpuinfo.parseCpuinfo("model"),
    architecture: cpuinfo.parseCpuinfo("architecture")
  )
  # except:
  #   return

proc eraseLogs*(): Future[Status] {.async.} =
  const find = "sudo find /var/log -type f"
  try:
    let 
      logs = execCmdEx(find)
      log = split(logs.output, "\n")
    for i, v in log:
      echo "sudo rm " & v
      let _ = execCmd(&"sudo rm " & $v)
      let _ = execCmd("sleep 1")
    discard execShellCmd("sudo rm /home/torbox/.bash_hitstory; sudo histroy -c")
    result = success
  except Exception:
    result = failure

proc getActiveIface*(): Future[ActiveIfaceList] {.async.} =
  const routeCmd = "sudo timeout 5 sudo route"
  let
    routeRes = execCmdEx(routeCmd)
  if routeRes.exitCode != 0:
    return
  let lines = routeRes.output.splitLines()
  try:
    for v in lines:
      let vv = v.splitWhitespace()
      case vv[0]
      of "default":
        result.input = vv[^1].parseIface
      of "192.168.42.0":
        result.output = vv[^1].parseIface
      of "tun0":
        result.hasVpn = true
  except: return

# proc hasVpn*(): Future[bool] {.async.} =

proc changePasswd*(currentPasswd, newPasswd, rnewPasswd: string; username: string = "torbox"): Future[bool] {.async.} =
  let
    cmdPasswd = &"(echo \"{currentPasswd}\"; sleep 1; echo \"{newPasswd}\"; sleep 1; echo \"{rnewPasswd}\") | passwd {username} >/dev/null 2>&1"
    cmdCode = execCmd(cmdPasswd)
  if cmdCode == 0:
    result = true