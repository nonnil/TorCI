import std / [
  os, osproc, asyncdispatch,
  json, strutils, strformat,
  options
]
import results, validateip
import torsocks, torcfg, bridges
import ".." / [ sys ]

export torsocks, bridges

type
  Tor* = ref object of RootObj
    ipaddr: string
    port: Port
    setting*: TorSettings
    status*: TorStatus
  
  TorSettings* = ref object
    bridge: Bridge

  TorStatus* = ref object
    isOnline: bool
    isVPN: bool
    exitIp: string
  
  R = Result[void, string]

method getIpaddr*(tor: Tor): Option[string] {.base.} =
  return some(tor.ipaddr)

method getPort*(tor: Tor): Option[Port] {.base.} =
  return some(tor.port)

method bridge*(tor: Tor): Bridge {.base.} =
  tor.setting.bridge

method isTor*(tor: var Tor): R {.base.} =
  const destHost = "https://check.torproject.org/api/ip"
  let checkTor = waitFor destHost.torsocks(tor.getIpaddr.get, tor.getPort.get)
  if checkTor.len == 0: result.err "connection failed"
  let jObj = parseJson(checkTor)
  if $jObj["IsTor"] == "true":
    tor.status.isOnline = true
    tor.status.exitIp = jObj["IP"].getStr()
    result.ok
  
method isOnline*(tor: Tor): bool {.base.} =
  tor.status.isOnline

method hasNewExitIp*(tor: Tor): bool {.base.} =
  var `new` = new Tor
  let _ = `new`.isTor
  if tor.status.exitIp != `new`.status.exitIp:
    tor.status.exitIp = `new`.status.exitIp
    return true

method reload*(setting: var TorSettings): Result[void, string] {.base.} =
  ?setting.bridge.reload

method reload*(tor: var Tor): Result[void, string] {.base.} =
  ?tor.setting.reload
  ?tor.isTor

# proc reload*(tor: var Tor): Future[Result[void, string]] {.async.} =
#   ?tor.setting.reload
#   ?tor.isTor

proc ipaddr*(tor: var Tor, ipaddr: string) =
  if not isValidIp4(ipaddr, "local"):
    raise newException(ValueError, "")
  tor.ipaddr = ipaddr

proc port*(tor: var Tor, port: Port) =
  tor.port = port

proc init*(ipaddr: string, port: Port): Tor =
  new result
  ipaddr(result, ipaddr)
  port(result, port)

proc renewTorExitIp*(): Future[bool] {.async.} =
  const cmd = "sudo -u debian-tor tor-prompt --run 'SIGNAL NEWNYM'"
  let newIp = execCmdEx(cmd)
  if newIp.output == "250 OK":
    return true
  
proc restartTor*() {.async.} =
  restartService "tor"
  
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
  
# when isMainModule:
#   let bridgesS = waitFor getBridgeStatuses()
#   echo "obfs4: ", bridgesS.obfs4
#   echo "meekAzure: ", bridgesS.meekAzure
#   echo "snowflake: ", bridgesS.snowflake
#   let check = socks5("https://ipinfo.io/products/ip-geolocation-api", "127.0.0.1", 9050.Port, POST, "input=37.228.129.5")
#   echo "result: ", check