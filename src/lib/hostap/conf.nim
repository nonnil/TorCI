import std / [
  options, strutils,
  os, osproc, asyncdispatch, 
  re, tables
]
import results, resultsutils
import ../ sys / [ service, iface ]
from ../ sys / sys import getRpiModel

const
  model3* = "Raspberry Pi 3 Model B Rev"
  hostapd* = "/etc" / "hostapd" / "hostapd.conf"
  crda* = "/etc" / "default" / "crda"
  hostapdBakup* = "/etc" / "hostapd" / "hostapd.conf.tbx"

type
  HostAp* = ref object of RootObj
    status: HostApStatus
    conf: HostApConf

  HostApStatus* = ref object of RootObj
    isActive: bool

  HostApConf* = ref object of RootObj
    iface: Option[IfaceKind]
    ssid: string
    password: string
    band: char
    channel: string
    isHidden: bool 
    power: string

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

proc default*(_: typedesc[HostAp]): HostAp =
  result = HostAp.new()
  result.conf = HostApConf.new()
  result.status = HostApStatus.new()

method conf*(hostap: HostAp): HostApConf {.base.} =
  hostap.conf

method status*(hostap: HostAp): HostApStatus {.base.} =
  hostap.status

method iface*(self: HostApConf): Option[IfaceKind] {.base.} =
  self.iface

method iface*(self: HostAp): Option[IfaceKind] {.base.} =
  self.conf.iface

method ssid*(self: HostApConf): string {.base.} =
  self.ssid

method ssid*(self: HostAp): string {.base.} =
  self.conf.ssid

method band*(self: HostApConf): char {.base.} =
  self.band

method band*(self: HostAp): char {.base.} =
  self.conf.band

method channel*(self: HostApConf): string {.base.} =
  self.channel

method channel*(self: HostAp): string {.base.} =
  self.conf.channel

method password*(self: HostApConf): string {.base.} =
  self.password

method getPassword*(self: HostAp): string {.base.} =
  self.conf.password

method isHidden*(self: HostApConf): bool {.base.} =
  self.isHidden

method isHidden*(self: HostAp): bool {.base.} =
  self.conf.isHidden

method isActive*(self: HostApStatus): bool {.base.} =
  self.isActive

method isActive*(self: HostAp): bool {.base.} =
  self.status.isActive

# proc parseIface(iface: string): IfaceKind =
#   parseEnum[IfaceKind](iface, unkwnIface) 

func iface*(self: var HostApConf, iface: string): Result[void, string] =
  let kind = iface.parseIfaceKind()
  self.iface = kind
  
  result.err("Invalid interface")

func iface*(self: var HostAp, iface: string): Result[void, string] =
  iface(self.conf, iface)

func ssid*(self: var HostApConf, ssid: string): Result[void, string] =
  if ssid.len > 32:
    result.err "Please set the SSID to 32 characters or less."
  elif ssid.match(re"^(^[A-Za-z0-9\-\_]+$)"):
    self.ssid = ssid
    result.ok
  else:
    result.err "Invalid SSID"

func ssid*(self: var HostAp, ssid: string): Result[void, string] =
  ssid(self.conf, ssid)

func band*(self: var HostApConf, band: char): Result[void, string] =
  let ord_band = ord(band.toLowerAscii)
  if ord_band == 97 or ord_band == 103:
    self.band = band
    result.ok
  else:
    result.err "Invalid band"

func band*(self: var HostApConf, band: string): Result[void, string] =
  # if band.len == 1 and band.match(re"^(a|g)$"):
  if band.len == 1:
    ?band(self, cast[char](band))
  else:
    result.err "Invalid band"

func band*(self: var HostAp, band: string): Result[void, string] =
  band(self.conf, band)

func channel*(self: var HostApConf, channel: string): Result[void, string] =
  if channels.hasKey(channel):
    self.channel = channel
    result.ok
  else:
    result.err "Invalid channel"

func channel*(self: var HostAp, channel: string): Result[void, string] =
  channel(self.conf, channel)

func password*(self: var HostApConf, password: string): Result[void, string] =
  if password.len > 64:
    result.err "Please set the password to 64 characters or less."
  elif password.len < 8:
    result.err "Please set the password to 8 characters or more"
  else:
    self.password = password
    result.ok

func password*(self: var HostAp, password: string): Result[void, string] =
  password(self.conf, password)

func cloak*(self: HostApConf, boolean: bool) =
  self.isHidden = boolean

func status*(self: var HostAp, status: HostApStatus) =
  self.status = status

func active*(self: var HostApStatus, isActive: bool) =
  self.isActive = isActive

func active*(self: var HostAp, isActive: bool) =
  active(self.status, isActive)

proc hostapdIsActive*(): bool =
  waitFor isActiveService("hostapd")

proc rpiIsModel3*(): Future[bool] {.async.} =
  match waitFor getRpiModel():
    Ok(): return true
    Err(): return false

proc getHostApConf*(): Future[HostApConf] {.async.} =
  try:
    result.new
    let lines = readFile(hostapd)
      .splitlines()

    for line in lines:
      if (line.len > 0) and (not line.startsWith("#")):
        let pair = split(line, "=")
        case pair[0]
        of "ssid": 
          let _ = ssid(result, pair[1])
        
        of "interface":
          let _ = iface(result, pair[1])

        of "band":
          let _ = band(result, pair[1])

        of "channel":
          let _ = channel(result, pair[1])

        of "ignore_broadcast_ssid":
          if pair[1] == "1":
            result.isHidden = true 

        of "password":
          let _ = password(result, pair[1])
  except:
    return

proc getHostApStatus*(): Future[HostApStatus] {.async.} =
  result.new
  result.isActive = hostapdIsActive()

proc getHostAp*(): Future[HostAp] {.async.} =
  result.new
  result.conf = await getHostApConf()
  result.status = await getHostApStatus()

proc parseConf*(s: seq[string]): Future[TableRef[string, string]] {.async.} =
  #var tuple_data = tuple[string, string]
  var table = newTable[string, string]()
  for v in s:
    if (v.len > 0) and (not v.startsWith("#")):
      let parsedStr = split(v, "=")
      #for i in parsed_str:
      #table.({parsed_str[0]: parsed_str[1]}.newTable)
      table[parsedStr[0]] = parsedStr[1]
  return table

proc getCrda(): Future[string] {.async.} =
  try:
    let f = readFile(crda)
    for v in f.splitLines():
      if v.startsWith("REGDOMAIN="):
        let vv = v.split("=")
        return vv[1]
  except:
    return

proc changeCrda() {.async.} =
  try:
    var country: string
    var f = readFile(crda)
    f = f.replace(re"REGDOMAIN=.*", "REGDOMAIN=" & country)
    crda.writeFile(f)
  except:
    return

  # # This last part resets the dhcp server and opens the iptables to access TorBox
  # # This fundtion has to be used after an ifup command
  # # Important: the right iptables rules to use Tor have to configured afterward
  # discard execCmd("sudo systemctl restart isc-dhcp-server")
  # discard execCmd("sudo /sbin/iptables -F")
  # discard execCmd("sudo /sbin/iptables -t nat -F")
  # discard execCmd("sudo /sbin/iptables -P FORWARD DROP")
  # discard execCmd("sudo /sbin/iptables -P INPUT ACCEPT")
  # discard execCmd("sudo /sbin/iptables -P OUTPUT ACCEPT")

proc disableAp*(flag: string = "") {.async.} =
  try:
    if flag == "permanentry":
      discard execCmd("sudo systemctl mask --now hostapd")
    stopService("hostapd")
    discard execCmd("sudo systemctl daemon-reload")
  except:
    return

proc enableWlan*() {.async.} =
  try:
    discard execCmd("sudo systemctl enable hostapd")
    startService("hostapd")
  except:
    return

method write*(hostapConf: HostApConf) {.base.} =
  try:
    # backup the hostapd.conf
    copyFile(hostapd, hostapdBakup)
    var stream = readFile(hostapd)
    
    let ssid = hostapConf.ssid
    if not ssid.isEmptyOrWhitespace():
      stream = stream.replace(re"ssid=.*", "ssid=" & ssid)

    let band = hostapConf.band
    if band.isAlphaAscii():
      if band == 'a':
        let coCode = waitFor getCrda()
        if coCode == "00":
          waitFor changeCrda()
        stream = stream.replace("hw_mode=g", "hw_mode=" & band)
        stream = stream.replace(re"channel.*", "channel=36")
        stream = stream.replace("#ht_capab=[HT40-][HT40+][SHORT-GI-20][SHORT-GI-40][DSSS_CCK-40]", "ht_capab=[HT40-][HT40+][SHORT-GI-20][SHORT-GI-40][DSSS_CCK-40]")

      else:
        stream = stream.replace("hw_mode=a", "hw_mode=g")
        stream = stream.replace(re"channel.*", "channel=6")
        stream = stream.replace("vht_oper_chwidth=1", "#vht_oper_chwidth=1")
        stream = stream.replace("vht_oper_centr_freq_seg0_idx=42", "#vht_oper_centr_freq_seg0_idx=42")

    let sig = hostapConf.channel
    if not sig.isEmptyOrWhitespace:
      let (channel, hf) = channels[sig]
      stream = stream.replace(re"channel=.*", "channel=" & $channel)

      if hf == 0:
        stream = stream.replace("vht_oper_chwidth=1", "#vht_oper_chwidth=1")
        stream = stream.replace("vht_oper_centr_freq_seg0_idx=42", "#vht_oper_centr_freq_seg0_idx=42")

      else:
        stream = stream.replace("#vht_oper_chwidth=1", "vht_oper_chwidth=1")
        stream = stream.replace("#vht_oper_centr_freq_seg0_idx=42", "vht_oper_centr_freq_seg0_idx=42")
      
    let password = hostapConf.password
    if not password.isEmptyOrWhitespace():
      stream = stream.replace(re"wpa_passphrase=.*", "wpa_passphrase=" & password)
    
    block:
      let cloak = if hostapConf.isHidden: "1" else: "0"
      stream = stream.replacef(re"ignore_broadcast_ssid=.*", "ignore_broadcast_ssid=" & cloak)

    writeFile(hostapd, stream)

  except:
    return

method write*(hostap: HostAp) {.base.} =
  hostap.conf.write

when isMainModule:
  when defined(dhclient):
    const cmd = "ps -ax | grep \"[d]hclient.wlan1\""
    let ps = execCmdEx(cmd)
    for v in ps.output.splitLines():
      let m = v.splitWhitespace(maxsplit = 4)
      let app = m[4]
      echo "app: ", app
      echo "line: ", m