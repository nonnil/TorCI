import strformat, strutils
import os, osproc, asyncdispatch
import results
import wifiScanner
import ".." / [ types, utils ]
import sys / iface

# var network: Network = new Network

type
  ConnectedAp* = ref object
    ssid*: string
    ipaddr*: string

template debugWpa(msg: string) =
  when defined(debugWpa):
    echo msg

template checkExitCode(res: tuple[output: TaintedString, exitCode: int]) =
  if res.exitcode != 0: return (code: false, msg: res.output)

proc inWlan*(iface: IfaceKind): bool = 
  if iface in {wlan0, wlan1}:
    return true
  
proc checkConnected(wpa: Network): bool =
  var network = wpa
  try:
    let wpaStatus = execCmdEx(&"wpa_cli -i {network.wlan} status")
    if wpaStatus.exitcode == 0:
      let
        lines = wpaStatus.output.splitLines()
        status = lines[8].split("=")[1]
      if status == "COMPLETED":
        return true
      else:
        return false
  except: return false

proc newWpa*(wlan: IfaceKind, autoconnect: bool = false): Future[Network] {.async.} =
  var network: Network = new Network
  # Interface to use
  network.wlan = wlan

  # wpa_supplicant log
  network.logFile = "/tmp" / &"tbm-{$network.wlan}.log"
  writeFile(network.logFile, "")
  debugWpa "created wpa log file"

  # config for wpa_supplicant
  network.configFile = "/etc" / "wpa_supplicant" / &"wpa_supplicant-{$network.wlan}.conf"
  if not fileExists(network.configFile):
    let buf = "ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev\nupdate_config=1\n"
    writeFile(network.configFile, buf)

  # Start wpa_supplicant
  discard execCmdEx(&"wpa_supplicant -i {$network.wlan} -c {network.configFile} -B -f {network.logFile}")
  
  if autoconnect == true:
    # Disable dhcp connection from current interface
    discard execCmdEx(&"dhclient -r {$network.wlan}")
    # Check if we got connect by wpa_supplicant
    # run dhcp for getting ip
    discard execCmdEx(&"dhclient {$network.wlan}")
    sleep(5)
    network.connected = checkConnected(network)
  result = network

proc disconnect*(wlan: IfaceKind) =
  try:
    # Disconnect from any network
    discard execCmdEx(&"dhclient -r {$wlan}")
    discard execCmdEx(&"wpa_cli -i {$wlan} disconnect")
  except: return

# const wpaLog = "/tmp" / &"tbm-{}"
proc newConnect(wpa: Network, data: tuple[essid, bssid, password : string]): tuple[code: bool, msg: string] =
  var network = wpa
  if not network.wlan.inWlan():
    return
  
  network.essid = data.essid
  network.bssid = data.bssid
  # network.password = data.password
  # network.isHidden = if data.essid == "-HIDDEN-": true else: false
  
  # we need to disconnect 1st If we are connected and trying to connect
  if network.connected:
    disconnect network.wlan
    debugWpa "Disconnected current network"

  if not network.hasNetworkId:
    # We get a new network id on wpa_supplicant
    let cmd = execCmdEx(&"wpa_cli -i {$network.wlan} add_network")
    echo "before network id: ", cmd.output
    try:
      let addNetwork = execCmdEx(&"wpa_cli -i {$network.wlan} add_network")
      if addNetwork.exitcode != 0:
        let networkId = parseInt(addNetwork.output.splitLines()[0])
        network.networkId = networkId
        debugWpa "network id: " & $networkId
      else: return (false, addNetwork.output)
    except: return (false, "")

  # Set the BSSID where we are going to connect
  var cmdRes = execCmdEx(&"wpa_cli -i {$network.wlan} set_network {$network.networkId} bssid \"{network.bssid}\"")
  debugWpa "[wpa] set_network: " & cmdRes.output

  # Set the essid where we are going to connect
  cmdRes = execCmdEx(&"wpa_cli -i {$network.wlan} set_network {$network.networkId} ssid \'\"{network.essid}\"\'")
  debugWpa "[wpa] set_network ssid: " & cmdRes.output

  if network.isEss:
    discard execCmdEx(&"wpa_cli -i {$network.wlan} set_network {$network.networkId}, key_mgmt NONE")

  elif data.password != "":
    # Set the password
    cmdRes = execCmdEx(&"wpa_cli -i {$network.wlan} set_network {$network.networkId} psk \'\"{data.password}\"\'")
    debugWpa "[wpa] set_network psk: " & cmdRes.output

  
  # Scan AP for hidden networks
  if network.isHidden:
    discard execCmdEx(&"wpa_cli -i {$network.wlan} set_network {$network.networkId} scan_ssid 1")

  # Enable network
  cmdRes = execCmdEx(&"wpa_cli -i {$network.wlan} enable_network {$network.networkId}")
  debugWpa "[wpa] enable_network: " & cmdRes.output
  checkExitCode cmdRes

  # Select the network
  cmdRes = execCmdEx(&"wpa_cli -i {$network.wlan} select_network {$network.networkId}")
  debugWpa "[wpa] select_network: " & cmdRes.output

  # Clean wpa_supplicant log
  try:
    removeFile(network.logFile)
    cmdRes = execCmdEx(&"wpa_cli -i {$network.wlan} relog")
    debugWpa "[wpa] relog: " & cmdRes.output
  except: return

  # FIXME: Log note
  debugWpa "before Log Note"
  cmdRes = execCmdEx(&"wpa_cli -i {$network.wlan} note Restarted")
  debugWpa "[wpa] note Restarted: " & cmdRes.output
  sleep 1

  # Check wpa_supplicant log for connect/error event
  # debugWpa "log file path: " & network.logFile
  debugWpa "before readFile"
  let logFile = readFile(network.logFile)
  debugWpa "logfile: " & $logFile
  var wpaEvent: string
  if contains(logFile, "CTRL-EVENT-CONNECTED"):
    wpaEvent = "CONNECTED"
  elif contains(logFile, "CTRL-EVENT-DISCONNECTED"):
    wpaEvent = "DISCONNECTED"
  elif contains(logFile, "CTRL-EVENT-ASSOC-REJECT"):
    wpaEvent = "DISCONNECTED"
  
  # Password error
  if wpaEvent == "DISCONNECTED":
    cmdRes = execCmdEx(&"wpa_cli -i {$network.wlan} disconnect")
    debugWpa "[wpa] disconnect: " & cmdRes.output
    checkExitCode cmdRes
    cmdRes = execCmdEx(&"wpa_cli -i {$network.wlan} remove_network {$network.networkId}")
    debugWpa "[wpa] remove_network: " & cmdRes.output
    checkExitCode cmdRes
    return (code: false, msg: "Password wrong.")

  # run dhcp for getting ip
  debugWpa "Trying run dhclient"
  cmdRes = execCmdEx(&"sudo dhclient {$network.wlan}")
  debugWpa "[dhclient] sudo dhclient: " & cmdRes.output
  checkExitCode cmdRes

  # Save wpa_supplicant config
  debugWpa "Trying save config"
  cmdRes = execCmdEx(&"wpa_cli -i {$network.wlan} save_config")
  debugWpa "[wpa] save_config: " & cmdRes.output
  return (true, "")

proc connect*(wlan: Network, data: tuple[essid, bssid, password: string]): Future[tuple[code: bool, msg: string]] {.async.}=
  # If network is already configured  connect without asking password
  # If security is ESS, we don't ask for password
  let network = wlan
  if not network.wlan.inWlan():
    return

  let lnCmd = execCmdEx(&"wpa_cli -i {network.wlan} list_networks | grep \"{data.bssid}\"")
  try:
    let networkId = lnCmd.output.split("\t")[0]
    debugWpa "networkId: " & networkId
    network.networkId = networkId.parseInt
    network.hasNetworkId = true
    disconnect network.wlan

  except: network.hasNetworkId = false
  
  result = newConnect(network, data)
  
  # if network.hasNetworkId == false and network.security != "[ESS]":
    
proc networkList*(network: Network): Future[WifiList] {.async.} =
  # wirelessInfo = await initialize(`interface`)
  # let network = initialize(wlan)
  if not network.wlan.inWlan:
    return
  var nl = await wifiScan(network.wlan)
  for i, el in nl:
    if el.essid.contains("\\x00") or el.essid.contains("?") or el.essid == "":
      nl[i].essid = "-HIDDEN-"
      nl[i].isHidden = true
  # network.wifiList = nl
  network.scanned = true
  result = nl
  # result = (code: true, msg: "", result: network.wifiList)

  # return network.wifiList
  # return (true, "", network.wifiList)
  
proc getConnectedAp*(wlan: IfaceKind): Future[Result[ConnectedAp, string]] {.async.} =
  # let wlan = wpa.wlan
  if not wlan.isWlan:
    return
  try:
    let wpaStatus = execCmdEx(&"wpa_cli -i {wlan} status")
    if wpaStatus.exitcode == 0:
      let
        lines = wpaStatus.output.splitLines()
        status = lines[8].split("=")[1]

      if status == "COMPLETED":
        let
          ssid = lines[2].split("=")[1]
          ipaddress = lines[9].split("=")[1]
        # wpa.connected = true
        result = ok ConnectedAp(ssid: ssid, ipaddr: ipaddress)

  except IOError as e:
    return err(e.msg)

# when isMainModule:
#   import parseopt
#   when defined(debugWpa):
#     var wpa = waitFor newWpa(wlan1)
#     wpa.connected = checkConnected(wpa)
#     let nl = networkList(wpa)
#     echo "is scanned: ", $wpa.scanned
#     if wpa.connected:
#       debugWpa "wifi is active"
#     let cmdRes = waitFor connect(wpa, (
#       essid: "",
#       bssid: "",
#       password: "",
#       sec: "",
#       )
#     )
#     echo "result: ", cmdRes
#     let curNet = waitFor currentNetwork(wpa)
#     echo "current network", $curNet
#   elif defined(testProcess):
#     var args = initOptParser(commandLineParams())
#     var wlan: string
#     for kind, key, val in args.getopt():
#       case kind
#       of cmdArgument:
#         continue
#       of cmdShortOption, cmdLongOption:
#         case key
#         of "wlan", "w":
#           if wlan.len == 0:
#             wlan = val
#       of cmdEnd:
#         continue
#     if wlan.len != 0:
#       echo "executing process"
#       var res = execProcess("sudo dhclient", args=[wlan])
#       echo "result: ", res