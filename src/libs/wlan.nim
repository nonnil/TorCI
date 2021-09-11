import asyncdispatch, tables, osproc, sequtils, strutils, strformat
import re
import ../types
import os

#proc getModuleName*(net: NetInterfaces; name: NetInterKind): Future[string] {.async.} =
const
  hostapd = "/etc/hostapd/hostapd.conf"
  hostapdBak = "/etc/hostapd/hostapd.conf.tbx"

proc parseTable*(s: seq[string]): Future[TableRef[string, string]] {.async.} =
  #var tuple_data = tuple[string, string]
  var table = newTable[string, string]()
  for v in s:
    if v != "":
      if not v.contains("#"):
        let parsedStr = split(v, "=")
        #for i in parsed_str:
        #table.({parsed_str[0]: parsed_str[1]}.newTable)
        table[parsedStr[0]] = parsedStr[1]
  return table

proc checker(s, flag: string): tuple[code: bool, msg: string]=
  case flag
  of "ssid":
    if s.len == 0: return
    if s.len <= 32 and s.match(re"^(^[A-Za-z0-9\-\_]+$)"):
      return (true, "")
    elif s.len > 32:
      return (false, "Please set to 32 characters or less.")
    else:
      return  (false, "")
  of "band":
    if s.len == 0: return
    if s.len == 1 and s.match(re"^(a|g)$"):
      return (true, "")
    else:
      return (false, "")
  of "password":
    if (s.len >= 8) and (s.len <= 64):
      return (true, "")
  else:
    return

# proc getModule(output: string): NetInterfaces =
#   case output
#   of $eth0:
#     result = NetInterfaces(kind: eth0, status: online)
#   of $eth1:
#     result = NetInterfaces(kind: eth1, status: online)
#   of $wlan0:
#     result = NetInterfaces(kind: wlan0, status: online)
#   of $wlan1:
#     result = NetInterfaces(kind: wlan1, status: online)

proc restartWlan*() =
  try:
    discard execShellCmd("(nohup /home/torbox/torbox/./hostapd_fallback) 2> /dev/null")
    discard execShellCmd("rm /home/torbox/torbox/nohup.out")
  except:
    return

proc disableAp*(flag: string = "") =
  try:
    discard execShellCmd("sudo systemctl stop hostapd")
    if flag == "permanentry":
      discard execShellCmd("sudo systemctl disable hostapd")
  except:
    return

proc enableWlan*() =
  try:
    discard execShellCmd("sudo systemctl enable hostapd")
    discard execShellCmd("sudo systemctl start hostapd")
  except:
    return

# proc getInputDevice*(): Future[NetInterfaces] {.async.} =
#   const cmdStr = "route | grep -m 1 default | tr -s \" \" | cut -d \" \" -f8"
#   try:
#     var cmd = execCmdEx(cmdStr)
#     # echo "WLAN module: ", $cmd.output.splitLines()[0]
#     let module = getModule(cmd.output.splitLines()[0])
#     return module
#     #result = (status: module.status, name: $module.kind)
#   except Exception:
#     return NetInterfaces(kind: wlan1, status: online)

proc getWlanInfo*(): Future[HostAp] {.async.} =
    #const copyFile = &"cp {hostapd_path} {hostapd_save}"
  try:
    var fr = splitLines(readFile(hostapd))
    # fr.delete(0, 5)
    # echo "Splited file lines: " & fr
    let tb = await parseTable(fr)
    # let crBand = await currentBand()
    # result = {"ssid": tb["ssid"], "band": crBand, "ssidCloak": tb["ignore_broadcast_ssid"]}.newTable
    result = HostAp(
      ssid: tb["ssid"],
      band: tb["hw_mode"],
      isHidden: if tb["ignore_broadcast_ssid"] == "1": true else: false,
      password: tb["wpa_passphrase"]
    )
  except:
    return

proc changeSsid*(ssid: string): Future[bool] {.async.} =
  # discard execShellCmd(&"sudo cp {hostapd_path} {hostapd_save}")
  try:
    copyFile(hostapd, hostapdBak)
    let
      fr = readFile(hostapd)
      rstr = fr.replacef(re"^ssid=.*", "ssid=" & ssid)
    writeFile(hostapd, rstr)
    # discard execShellCmd(&"sudo sed -i \"s/^ssid=.*/{name}/\" {hostapd_path} ")
    # discard execShellCmd("sleep 2")
    restartWlan()
    return true
  except:
    return false

proc setWlanConfig*(hostap: HostAp): Future[bool] {.async.} =
  try:
    copyFile(hostapd, hostapdBak)
    var fr = readFile(hostapd)
    if checker(hostap.ssid, "ssid").code:
      fr = fr.replacef(re"ssid=.*", "ssid=" & hostap.ssid)
    if checker(hostap.band, "band").code:
      fr = fr.replacef(re"hw_mode=.*", "hw_mode=" & hostap.band)
      fr = fr.replacef(re"channel.*", "channel=36")
    if checker(hostap.password, "password").code:
      fr = fr.replacef(re"wpa_passphrase=.*", "wpa_passphrase=" & hostap.password)
    let input: int = if hostap.isHidden: 1
                     else: 0
    fr = fr.replacef(re"ignore_broadcast_ssid=.*", "ignore_broadcast_ssid=" & $input)
    writeFile(hostapd, fr)
    return true
  except:
    return false
