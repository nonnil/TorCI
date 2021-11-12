import tables, osproc, strutils, strformat
import re
import asyncdispatch
import ../types
# type

  # WlanKind* = enum
  #   wlan0, wlan1
  
  # EthKind* = enum
  #   eth0, eth1
  
  # ExtInterKind* = enum
  #   usb0, ppp0
  
  # Wifi* = object of RootObj
  #   bssid*: string
  #   channel*: string
  #   dbmSignal*: string
  #   quality*: string
  #   security*: string
  #   essid*: string
  #   isEss*: bool
  #   isHidden*: bool

  # WifiList* = seq[Wifi]
  # Wifi* = object of RootObj
  #   bssid*: string
  #   channel*: string
  #   dbmSignal*: string
  #   quality*: string
  #   security*: string
  #   essid*: string

  # WifiList* = seq[Wifi]
  # WifiData = OrderedTable[seq[string]]
  
let channelFreq: Table[int, int] = {
  2: 2417,
  3: 2422,
  1: 2412,
  5: 2432,
  6: 2437,
  7: 2442,
  4: 2427,
  8: 2447,
  9: 2452,
  10: 2457,
  11: 2462,
  12: 2467,
  13: 2472,
  14: 2484
}.toTable

let channelFreq5ghz: Table[int, int] = {
  7: 5035,
  8: 5040,
  9: 5045,
  11: 5055,
  12: 5060,
  16: 5080,
  32: 5160,
  34: 5170,
  36: 5180,
  38: 5190,
  40: 5200,
  42: 5210,
  44: 5220,
  46: 5230,
  48: 5240,
  50: 5250,
  52: 5260,
  54: 5270,
  56: 5280,
  58: 5290,
  60: 5300,
  62: 5310,
  64: 5320,
  68: 5340,
  96: 5480,
  100: 5500,
  102: 5510,
  104: 5520,
  106: 5530,
  108: 5540,
  110: 5550,
  112: 5560,
  114: 5570,
  116: 5580,
  118: 5590,
  120: 5600,
  122: 5610,
  124: 5620,
  126: 5630,
  128: 5640,
  132: 5660,
  134: 5670,
  136: 5680,
  138: 5690,
  140: 5700,
  142: 5710,
  144: 5720,
  149: 5745,
  151: 5755,
  153: 5765,
  155: 5775,
  157: 5785,
  159: 5795,
  161: 5805,
  165: 5825,
  169: 5845,
  173: 5865,
  183: 4915,
  184: 4920,
  185: 4925,
  187: 4935,
  188: 4940,
  189: 4945,
  192: 4960,
  196: 4980
}.toTable

proc zip[A, B](t1: Table[A, B]; t2: Table[A, B]): Table[A, B] =
  result = t1
  for k, v in t2.pairs:
    result[k] = v

let channels: Table[int, int] = zip(channelFreq, channelFreq5ghz)

proc isChannels(ch: int): bool =
  # for v in channels.values:
  #   if ch == v:
  #     return true
  if ch in channels:
    return true
    
proc exclusion(s: string): bool =
  case s
  of $eth0: return false
  of $eth1: return false
  of $wlan0: return true
  of $wlan1: return true
  of $ppp0: return true
  of $usb0: return true
  else: return false

proc sort(strs: seq[string]): WifiList =
  for v in strs:
    if v.len == 0:
      continue
    let
      lines = v.split("\t")
      quality = 2 * (lines[2].parseInt + 100)
    result.add Wifi(
      bssid: lines[0],
      channel: if isChannels(lines[1].parseInt): $lines[1] else: "?",
      dbmSignal: $lines[2],
      quality: if quality > 100: $100 else: $quality,
      security: try: lines[3].findAll(re"\[(.*?)\]")[0] except: "unknown",
      essid: try: $lines[4] except: "?"
    )


proc wifiScan*(wlan: IfaceKind): Future[WifiList] {.async.} =
  try:
    var wpaScan = execCmdEx(&"wpa_cli -i {wlan} scan")
    # sleep 1
    if wpaScan.exitCode == 0:
      var scanResult = execCmdEx(&"wpa_cli -i {wlan} scan_results")
      if scanResult.output.splitLines().len <= 1:
        wpaScan  = execCmdEx(&"wpa_cli -i {wlan} scan")
        scanResult = execCmdEx(&"wpa_cli -i {wlan} scan_results")
      var r = scanResult.output.splitLines()
      r.delete 0
      # return (code: true, msg: "", list: r.sort())
      return r.sort()
      # result.data = r.sort()
      # result.code = true
    elif wpaScan.output == "Failed to connect to non-global ctrl_ifname:":
      # return (code: false, msg: wpaScan.output, list: @[Wifi()])
      return
    else:
      # return (code: false, msg: wpaScan.output, list: @[Wifi()])
      return
  except:
    # return (code: false, msg: "Something went wrong", list: @[Wifi()])
    return
  # else: return (code: false, msg: "Invalid interface", data: @[Wifi()])

# when isMainModule:
#   when defined(debugWifiScan):
#     var r = wpaResult.splitLines()
#     r.delete 0
#     var res: WifiList
#     res = r.sort()
#     for i, el in res:
#       if el.essid.contains("\\x00") or el.essid.contains("?") or el.essid == "":
#         res[i].essid = "-HIDDEN-"
#     echo res
#   when defined(debugSsidSecurity):
#     var r = wpaResult.splitLines()
#     r.delete 0
#     var res: WifiList
#     res = r.sort()