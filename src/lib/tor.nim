import os, osproc, asyncdispatch, json, strutils, strformat
import torsocks
import ".." / [types]
import sys, bridges
from consts import torlog, torrc

export torsocks

proc isTor*(cfg: Config): Future[tuple[isTor: bool, ipAddr: string]] {.async.} =
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
    torch = await isTor(cfg)
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