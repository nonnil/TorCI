import os, osproc, asyncdispatch, re, json, strutils, strformat
import libcurl
import ".."/[types]
import syslib, bridges

proc curlWriteFn(
  buffer: cstring,
  size: int,
  count: int,
  outstream: pointer): int =
  
  let outbuf = cast[ref string](outstream)
  outbuf[] &= buffer
  result = size * count

proc socks5(url, address: string, port: Port, prt: Protocol = GET, data: string = ""): string =
  let curl = easy_init()
  let webData: ref string = new string
  discard curl.easy_setopt(OPT_USERAGENT,
    "Mozilla/5.0 (Windows NT 10.0; rv:78.0) Gecko/20100101 Firefox/78.0")
  case prt
  of GET:
    discard curl.easy_setopt(OPT_HTTPGET, 1)
  of POST:
    discard curl.easy_setopt(OPT_HTTPPOST, 10000)
    discard curl.easy_setopt(OPT_POSTFIELDS, data)
  discard curl.easy_setopt(OPT_WRITEDATA, webData)
  discard curl.easy_setopt(OPT_WRITEFUNCTION, curlWriteFn)
  discard curl.easy_setopt(OPT_URL, url)
  discard curl.easy_setopt(OPT_PROXYTYPE, 5)
  discard curl.easy_setopt(OPT_PROXY, address)
  discard curl.easy_setopt(OPT_PROXYPORT, port)
  discard curl.easy_setopt(OPT_TIMEOUT, 5)

  let ret = curl.easy_perform()
  if ret == E_OK:
    result = webData[]
  else: return

# proc torsocks*(url, address: string, port: Port, ): Future[string] {.async.} = 
#   result = url.socks5req(address, port)

proc torsocks*(url: string, cfg: Config, prtc: Protocol = GET): Future[string] {.async.} =
  let
    address = cfg.torAddress
    port = cfg.torPort.parseInt.Port
  result = url.socks5(address, port, prtc)

proc torsocks*(url: string, address: string = "127.0.0.1", port: Port = 9050.Port, prtc: Protocol = GET): Future[string] {.async.} =
  result = url.socks5(address, port, prtc)

proc checkTor*(cfg: Config): Future[tuple[isTor: bool, ipAddr: string]] {.async.} =
  try:
    const
      destHost = "https://check.torproject.org/api/ip"
    let
      torch = await destHost.torsocks(cfg)
    if torch.len != 0:
      let jObj = parseJson(torch)
      if $jObj["IsTor"] == "true":
        result.isTor = true
      result.ipAddr = jObj["IP"].getStr()
  except:
    return

proc getTorStatus*(cfg: Config): Future[TorStatus] {.async.} =
  let
    torch = await checkTor(cfg)
    bridges = await getBridgeStatuses()
  result.isOnline = torch.isTor
  result.exitIp = torch.ipAddr
  result.useObfs4 = bridges.obfs4
  result.useMeekAzure = bridges.meekAzure
  result.useSnowflake = bridges.snowflake
  
proc renewTorExitIp*(): Future[bool] {.async.} =
  const cmd = "sudo -u debian-tor tor-prompt --run 'SIGNAL NEWNYM'"
  let newIp = execCmdEx(cmd)
  echo "renewTor IP: ", &"\"{newIp.output}\""
  if newIp.output == "250 OK":
    return true
  
proc restartTor*() {.async.} =
  restartService("tor")
  
proc getTorLog*(): Future[string] {.async.} =
  if not fileExists(torlog):
    return
  let f = readFile(torlog)
  result = f
  
proc spawnTorrc*() =
  const
    torrcOrig = "/home" / "torbox" / "torbox" / "etc" / "tor" / "torrc"
  if not fileExists(torrcOrig):
    return
  copyFile torrcOrig, torrc
  
# proc activateBridges*()
  
when isMainModule:
  let bridgesS = waitFor getBridgeStatuses()
  echo "obfs4: ", bridgesS.obfs4
  echo "meekAzure: ", bridgesS.meekAzure
  echo "snowflake: ", bridgesS.snowflake
  let check = socks5("https://ipinfo.io/products/ip-geolocation-api", "127.0.0.1", 9050.Port, POST, "input=37.228.129.5")
  echo "result: ", check