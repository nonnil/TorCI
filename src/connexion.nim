#import shell
import re, asyncdispatch, osproc, strutils, strformat, sequtils, re
import httpclient, json
import types
import libs/[hostAp, syslib, session, wifiScanner]
#import net, nativesockets, httpclient

export asyncdispatch
export hostAp, syslib, session, wifiScanner

const torrc = "/etc/tor/torrc"

proc torStatus*(cfg: Config): Future[Status] {.async.} =
  try:
    const
      userAgent = "\"Mozilla/5.0 (Windows NT 10.0; rv:78.0) Gecko/20100101 Firefox/78.0\""
      destHost = "https://check.torproject.org/api/ip"
    let
      torAddress = cfg.torAddress
      torPort = cfg.torPort
    let
      cmdfull = &"curl --socks5 {torAddress}:{torPort} -A {userAgent} -m 5 -s {destHost} | cat | xargs"
      cmdStatus = execCmdEx(cmdfull)
    echo $cmdStatus
    if cmdStatus.exitCode == 0:
      if cmdStatus.output.len == 0:
        echo "Tor check: ", cmdStatus.output
        let jObj = parseJson(cmdStatus.output)
        echo jObj["IsTor"]
        if $jObj["IsTor"] == "true":
          return active
    echo "Tor check is fail."
    return deactive
  except:
    return
  #result = status.output

proc torLogs*():Future[string] {.async.} =
  if system.hostCPU != "arm":
    let f = readFile("notices.log")
  else:
    const cmdStr: string = "sudo tail -f -n 25 /var/log/tor/notices.log"
    let cmd = execCmdEx(cmdStr)
    if cmd.exitcode == 0:
      result = cmd.output
    else:
      return
  
proc restartTor*(): Future[Status] {.async.} =
  let cmd = execCmd("sudo systemctl restart tor &")
  if cmd == 0:
    return success
  else:
    return failure

proc displayAboutBridges*(): Future[string] {.async.} =
  # for Debugs.
  const temp = """
BRIDGES, which support pluggable transports, help Tor to circumvent sophisticated censorship. Regarding pluggable transports, TorBox currently supports only OBFS4, because it is to date the most effective transport to bypass censorship (meek-azure probably follows later).

3-STEP PROCEDURE
To get bridges working in TorBox, you have to follow a 3-step procedure:
1. Activate the BRIDGE MODE (menu entry 2).
2. Activate already configured bridges or add/replace new bridges.
3. Restart Tor.

HOW TO OBTAIN BRIDGES?
With TorBox, you have three ways to obtain bridges:
1. Obtain about every 24h one bridge automatically (menu entry 4).
2. Get them here: https://bridges.torproject.org/
   (chose "Advanced Options", "obfs4" and press "Get Bridges).
3. Send an email to bridges@torproject.org, using an address from Riseup
   or Gmail with "get transport obfs4" in the body of the mail.

HOW DO I KNOW IF IT IS WORKING?
PLEASE BE PATIENT! The process to build circuits could last for several minutes, depending on your network and the contacted bridge relay! In the end, you should see "Bootstrapped 100%: Done" (menu entry 9 or 11).

HOW CAN I CHECK THE VALIDITY OF A BRIDGE?
Use menu entry 3 or go to https://metrics.torproject.org/rs.html and search for the fingerprint (this is the long number between the ip:port and cert=). Tor Metrics should then show you the information of that particular server. If it doesn't show up, the bridge is no longer valid.
  """
  try:
    let cmdCode = execCmdEx("cat ../text/help-bridges-text")
    if cmdCode.exitcode == 0:
      result = cmdCode.output
    else:
      return temp
  except:
    result = temp

proc checkBridgeService*(): Future[Status] {.async.} =
  try:
    var cmd = execCmdEx(&"grep \"UseBridges\" {torrc}")
    if cmd.exitCode == 0:
      cmd[0].stripLineEnd()
      if cmd.output == "UseBridges 1":
        return active
      else:
        return deactive
    return deactive
  except:
    echo "Failed bridge check."
    result = deactive
  
proc displayBridgesDoc*(code: int): Future[string] {.async.} =
  const path = @[
    "text/activate-bridges-text", 
    "text/deactivate-bridges-text"
  ]
  if code == 0:
    let doc = readFile(path[0]) 
    result = doc
  elif code == 1:
    let doc = readFile(path[1])
    result = doc

proc actionerTorBridge*(code: int = 0): Future[Status] {.async.} =
  # Activer bridge
  if code == 1:
    let cmd = execCmdex(&"""sudo sed -i \"s/^#UseBridges/UseBridges/g\"{torrc} && 
sudo sed -i \"s/^#UpdateBridgesFromAuthority/UpdateBridgesFromAuthority/g\" {torrc} && 
sudo sed -i \"s/^#ClientTransport/ClientTransport/g\" {torrc}""")
    if cmd.exitcode == 0:
      return success
    else:
      return failure
  # désactiver bridge
  else:
    #let cmdTemp = "sudo sed -i \"s/^UseBridges/#UseBridges/g\"" & torrc
    let _ = execCmdex(&"""sudo sed -i \"s/^UseBridges/#UseBridges/g\"{torrc} && 
sudo sed -i \"s/^UpdateBridgesFromAuthority/#UpdateBridgesFromAuthority/g\" {torrc} && 
sudo sed -i \"s/^ClientTransport/#ClientTransport/g\" {torrc} && 
sudo sed -i \"s/^Bridge /#Bridge /g\" {torrc}""")
    let rt = await restartTor()
    if rt == success:
      return success
    else:
      return failure
  
proc loadBridgeList(): Future[array[2, seq[string]]] {.async.} =
  when system.hostCPU != "arm":
    const torrc = "/usr/local/etc/tor/torrc"
  var
    torrcL = splitLines(readFile(torrc))
    activatedBridges: seq[string]
    deactivatedBridges: seq[string]
  if torrcL.len > 0:
    for i, v in torrcL:
      if match(v, re"^#Bridge "):
        activatedBridges.add(v)    
  if torrcL.len > 0:
    for i, v in torrcL:
      if match(v, re"^Bridge "):
        deactivatedBridges.add(v) 
  return [activatedBridges, deactivatedBridges]

proc checkBridgeDB(hash: string): Future[string] {.async.} =
  let uri: string = "https://onionoo.torproject.org/details?lookup=$1" % [hash]
  #var socket = newSocket()
  #socket.connect("127.0.0.1", 9050.Port)
  let client = newAsyncHttpClient()
  let resp = await client.getContent(uri)
  return resp

proc listAllBridges*() {.async.} =
  let list = await loadBridgeList()
  var
    bridgeAddress: seq[string]
    bridgeStatus: string
    bridgeHash: string
  if list[1].len > 0:
    for i, v in list[1]:
      bridgeAddress = splitWhitespace(v, 3)
      bridgeHash = bridgeAddress[3]
      var test = await checkBridgeDB(bridgeHash)

  if list[0].len > 0:
    for v in list[0]:
      bridgeAddress = splitWhitespace(v, 3)