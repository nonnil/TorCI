import std / [
  options, strutils
]

type
  IfaceKind* = enum
    wlan0, wlan1,
    eth0, eth1,
    ppp0, usb0,
    tun0

  Iface* = ref object
    kind: IfaceKind
    status: IfaceStatus

  IfaceStatus* = ref object
    internet: IfaceKind
    hostap: IfaceKind
    vpnIsActive: bool

proc isEth*(iface: IfaceKind): bool =
  iface == eth0 or iface == eth1

proc isWlan*(iface: IfaceKind): bool =
  iface == wlan0 or iface == wlan1

proc parseIfaceKind*(iface: string): Option[IfaceKind] =
  try:
    let ret = parseEnum[IfaceKind](iface)
    return some(ret)
  except: return none(IfaceKind)

proc isIface*(iface: IfaceKind): bool =
  if iface in { wlan0, wlan1, eth0, eth1, ppp0, usb0, tun0 }:
    return true
  # let ret = iface.parseIfaceKind()
  # ret.isSome:
  #   return true