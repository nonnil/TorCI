import std / [
  os, osproc,
  nativesockets, asyncdispatch,
  json, strutils,
  options
]
import results
import torsocks, torcfg, bridges
import ../ sys / [ service ]

export torsocks, bridges

type
  TorInfo* = ref object of RootObj
    # setting*: TorSettings
    status*: TorStatus
    bridge*: Bridge

  # TorSettings* = ref object
  #   bridge: Bridge

  TorStatus* = ref object
    isTor*: bool
    isVPN*: bool
    exitIp*: Option[string]

proc checkTor*(torAddr: string, port: Port): Future[Result[TorStatus, string]] {.async.} =
  const destHost = "https://check.torproject.org/api/ip"
  let checkTor = waitFor destHost.torsocks(torAddr, port)
  if checkTor.len == 0: result.err "connection failed"
  try:
    let jObj = parseJson(checkTor)
    if $jObj["IsTor"] == "true":
      var ts = TorStatus.new
      ts.isTor = true
      ts.exitIp = some jObj["IP"].getStr()
      result.ok ts
  except JsonParsingError as e: return err(e.msg)

proc loadTorInfo*(torAddr: string, port: Port): Future[TorInfo] {.async.} =
  let
    status = waitFor checkTor(torAddr, port)
    bridge = waitfor loadBridge()

  result = new TorInfo
  result.status = status.get
  result.bridge = bridge.get

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