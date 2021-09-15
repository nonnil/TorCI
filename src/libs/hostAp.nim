import asyncdispatch, tables, osproc, sequtils, strutils, strformat
import re
import ../types
import os

#proc getModuleName*(net: NetInterfaces; name: NetInterKind): Future[string] {.async.} =
const
  hostapd = "/etc" / "hostapd" / "hostapd.conf"
  hostapdBak = "/etc" / "hostapd" / "hostapd.conf.tbx"
  crda = "/etc" / "default" / "crda"

const
  channels = {
    "ga": (1, 0), "gb": (1, 1), "gc": (2, 0), 
    "gd": (2, 1), "ge": (3, 0), "gf": (3, 1),
    "gg": (4, 0), "gh": (4, 1), "gi": (5, 0), 
    "gj": (5, 1), "gk": (6, 0), "gl": (6, 1), 
    "gm": (7, 0), "gn": (8, 0), "go": (8, 1), 
    "gp": (8, 1), "gq": (9, 0), "gr": (9, 1), 
    "gs": (10, 0), "gt": (10, 1), "gu": (11, 0),
    "gv": (11, 1),
    "aa": (36, 0), "ab": (36, 1), "ac": (40, 0),
    "ad": (40, 1), "ae": (44, 0), "af": (44, 1),
    "ag": (48, 0), "ah": (48, 1)
  }.toOrderedTable()

proc parseConf*(s: seq[string]): Future[TableRef[string, string]] {.async.} =
  #var tuple_data = tuple[string, string]
  var table = newTable[string, string]()
  for v in s:
    if v != "":
      if not v.startsWith("#"):
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

  of "channel":
    if s.len == 0: return
    if channels.hasKey(s):
      return (true, "")

  of "password":
    if (s.len >= 8) and (s.len <= 64):
      return (true, "")

  else:
    return

proc getCrda(): string =
  try:
    let f = readFile(crda)
    for v in f.splitLines():
      if v.startsWith("REGDOMAIN="):
        let vv = v.split("=")
        return vv[1]
  except:
    return

proc changeCrda() =
  try:
    var country: string
    var f = readFile(crda)
    f = f.replace(re"REGDOMAIN=.*", "REGDOMAIN=" & country)
    crda.writeFile(f)
  except:
    return

proc restartHostAp*() =
  const
    ipCmd = "ip addr show wlan1 | grep -w \"192.168.42.1\""
    restartCmd = "sudo systemctl restart hostapd"
    statusCmd = "sudo systemctl is-active hostapd"
  try:
    discard execShellCmd("(nohup /home/torbox/torbox/./hostapd_fallback) 2> /dev/null")
    discard execShellCmd("rm /home/torbox/torbox/nohup.out")
    let ip = execCmdEx(ipCmd)

    if ip.output.len != 0:
      var f = readFile hostapd
      f = f.replace("interface=wlan0", "interface=wlan1")
      writeFile hostapd, f

    discard execCmdEx(restartCmd)

    if ip.output.len != 0:
      var f = readFile hostapd
      f = f.replace("interface=wlan1", "interface=wlan0")
      writeFile hostapd, f
    let status = execCmdEx(statusCmd).output

    if status == "activating" or status == "inactive":
      copyFile hostapdBak, hostapd

      if ip.output.len != 0:
        var f = readFile hostapd
        f = f.replace("interface=wlan1", "interface=wlan0")
        writeFile hostapd, f

      discard execCmdEx(restartCmd)

      if ip.output.len != 0:
        var f = readFile hostapd
        f = f.replace("interface=wlan1", "interface=wlan0")
        writeFile hostapd, f
      
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

proc getHostApConf*(): Future[HostApConf] {.async.} =
    #const copyFile = &"cp {hostapd_path} {hostapd_save}"
  try:
    var fr = splitLines(readFile(hostapd))
    # fr.delete(0, 5)
    # echo "Splited file lines: " & fr
    let tb = await parseConf(fr)
    # let crBand = await currentBand()
    # result = {"ssid": tb["ssid"], "band": crBand, "ssidCloak": tb["ignore_broadcast_ssid"]}.newTable
    result = HostApConf(
      ssid: tb["ssid"],
      band: tb["hw_mode"],
      channel: tb["channel"],
      isHidden: if tb["ignore_broadcast_ssid"] == "1": true else: false,
      password: tb["wpa_passphrase"]
    )
  except:
    return

proc setHostApConf*(conf: HostApConf): Future[bool] {.async.} =
  try:
    copyFile(hostapd, hostapdBak)
    var fr = readFile(hostapd)

    if checker(conf.ssid, "ssid").code:
      fr = fr.replace(re"ssid=.*", "ssid=" & conf.ssid)

    if checker(conf.channel, "channel").code:
      let (channel, hf) = channels[conf.channel]
      fr = fr.replace(re"channel=.*", "channel=" & $channel)

      if hf == 0:
        fr = fr.replace("vht_oper_chwidth=1", "#vht_oper_chwidth=1")
        fr = fr.replace("vht_oper_centr_freq_seg0_idx=42", "#vht_oper_centr_freq_seg0_idx=42")

      else:
        fr = fr.replace("#vht_oper_chwidth=1", "vht_oper_chwidth=1")
        fr = fr.replace("#vht_oper_centr_freq_seg0_idx=42", "vht_oper_centr_freq_seg0_idx=42")

    if checker(conf.band, "band").code:
      if conf.band == "a":
        let coCode = getCrda()
        if coCode == "00":
          changeCrda()
        fr = fr.replace("hw_mode=g", "hw_mode=" & conf.band)
        fr = fr.replace(re"channel.*", "channel=36")
        fr = fr.replace("#ht_capab=[HT40-][HT40+][SHORT-GI-20][SHORT-GI-40][DSSS_CCK-40]", "ht_capab=[HT40-][HT40+][SHORT-GI-20][SHORT-GI-40][DSSS_CCK-40]")
      else:
        fr = fr.replace("hw_mode=a", "hw_mode=g")
        fr = fr.replace(re"channel.*", "channel=6")
        fr = fr.replace("vht_oper_chwidth=1", "#vht_oper_chwidth=1")
        fr = fr.replace("vht_oper_centr_freq_seg0_idx=42", "#vht_oper_centr_freq_seg0_idx=42")
        
    if checker(conf.password, "password").code:
      fr = fr.replace(re"wpa_passphrase=.*", "wpa_passphrase=" & conf.password)

    let input: int = if conf.isHidden: 1
                     else: 0

    fr = fr.replacef(re"ignore_broadcast_ssid=.*", "ignore_broadcast_ssid=" & $input)
    writeFile(hostapd, fr)
    restartHostAp()

    return true

  except:
    return false
