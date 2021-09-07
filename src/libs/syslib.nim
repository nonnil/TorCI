import asyncdispatch, strutils, strformat, re, tables
import os, osproc, json
import ../types
import wirelessManager
import libcurl

proc curlWriteFn(
  buffer: cstring,
  size: int,
  count: int,
  outstream: pointer): int =
  
  let outbuf = cast[ref string](outstream)
  outbuf[] &= buffer
  result = size * count

proc socks5Req(url, address: string, port: Port): string =
  let curl = easy_init()
  let webData: ref string = new string
  discard curl.easy_setopt(OPT_USERAGENT,
    "Mozilla/5.0 (Windows NT 10.0; rv:78.0) Gecko/20100101 Firefox/78.0")
  discard curl.easy_setopt(OPT_HTTPGET, 1)
  discard curl.easy_setopt(OPT_WRITEDATA, webData)
  discard curl.easy_setopt(OPT_WRITEFUNCTION, curlWriteFn)
  discard curl.easy_setopt(OPT_URL, url)
  discard curl.easy_setopt(OPT_PROXYTYPE, 5)
  discard curl.easy_setopt(OPT_PROXY, address)
  discard curl.easy_setopt(OPT_PROXYPORT, port)
  discard curl.easy_setopt(OPT_TIMEOUT, 5)

  let ret = curl.easy_perform()
  if ret == E_OK:
    # echo "Done"
    result = webData[]
  else: return

proc torsocks*(url, address: string, port: Port): Future[string] {.async.} = 
  result = url.socks5Req(address, port)
  
proc torsocks*(url: string, cfg: Config): Future[string] {.async.} = 
  let
    address = cfg.torAddress
    port = cfg.torPort.parseInt.Port
  result = url.socks5Req(address, port)

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

proc getSystemInfo*(): Future[SystemInfo] {.async.} = 
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
      case vv[0]
      of "tun0":
        result.hasVpn = true
  except: return

proc isTorActive*(cfg: Config): Future[bool] {.async.} =
  try:
    const
      userAgent = "\"Mozilla/5.0 (Windows NT 10.0; rv:78.0) Gecko/20100101 Firefox/78.0\""
      destHost = "https://check.torproject.org/api/ip"
    # let
    #   torAddress = cfg.torAddress
    #   torPort = cfg.torPort
    let
      # cmdfull = &"curl --socks5 {torAddress}:{torPort} -A {userAgent} -m 5 -s {destHost} | cat | xargs"
      # cmdStatus = execCmdEx(cmdfull)
      torch = await destHost.torsocks(cfg)
    if torch.len != 0:
      # if cmdStatus.output.len == 0:
      let jObj = parseJson(torch)
      if $jObj["IsTor"] == "true":
        return true
    echo "Tor check is fail."
    return false
  except:
    return

proc getOnlineIO*(): Future[tuple[inputIo, outputIo: string]] {.async.} =
  const routeCmd = "sudo timeout 5 sudo route"
  # when defined(debugCi):
    # return "wlan1"
  try:
    let routeRes = execCmdEx(routeCmd)
    let lines = routeRes.output.splitLines()
    for v in lines:
      let vv = v.splitwhitespace()
      case vv[0]
      of "default":
        result.inputIo = vv[^1]
      of "192.168.42.0":
        result.outputIo = vv[^1]
  except:
    return

# proc hasVpn*(): Future[bool] {.async.} =

proc changePasswd*(currentPasswd, newPasswd, rnewPasswd: string; username: string = "torbox"): Future[bool] {.async.} =
  let
    cmdPasswd = &"(echo \"{currentPasswd}\"; sleep 1; echo \"{newPasswd}\"; sleep 1; echo \"{rnewPasswd}\") | passwd {username} >/dev/null 2>&1"
    cmdCode = execCmd(cmdPasswd)
  if cmdCode == 0:
    result = true

  # discard getSystemInfo()

when isMainModule:
  const url = "https://check.torproject.org/api/ip"
  let ret = waitFor url.torsocks("127.0.0.1", 9050.Port)
  if ret.len != 0:
    let jObj = parseJson(ret)
    echo "IsTor: ", jObj{"IsTor"}