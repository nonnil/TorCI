import std / [
  asyncdispatch, strutils, strformat,
  re, tables, os, osproc, options
]
import results, validateip
import ".." / [ types ]
import hostap
import sys / [ iface ]

type
  SystemInfo* = object
    architecture*: string
    kernelVersion*: string
    model*: string
    uptime*: int
    localtime*: int
    torboxVer*: string

  IO* = ref object
    internet: IfaceKind
    hostap: IfaceKind
    vpnIsActive: bool

  Devices* = ref object
    devs: seq[Device]

  Device* = ref object
    macaddr: string
    ipaddr: string
    signal: string

method getDevs*(devs: Devices): seq[Device] {.base.} =
  devs.devs

method getInternet*(io: IO): Option[IfaceKind] {.base.} =
  if len($io.internet) != 0:
    return some(io.internet)

method getHostap*(io: IO): Option[IfaceKind] {.base.} =
  if len($io.hostap) != 0:
    return some io.hostap

method getMacaddr*(dev: Device): Option[string] {.base.} =
  if dev.macaddr.len > 0:
    return some(dev.macaddr)

method getIpaddr*(dev: Device): Option[string] {.base.} =
  if dev.ipaddr.len > 0:
    return some(dev.ipaddr)

method getSignal*(dev: Device): Option[string] {.base.} =
  if dev.signal.len > 0:
    return some(dev.signal)

method vpnIsActive*(io: IO): bool {.base.} =
  io.vpnIsActive

proc internet*(io: var IO, iface: IfaceKind) =
  io.internet = iface

proc hostap*(io: var IO, iface: IfaceKind): Result[void, string] =
  case iface
  of wlan0, wlan1:
    io.hostap = iface
    result.ok
  
  else:
    result.err "should be set to wireless interface"

proc vpn*(io: var IO, isAcitve: bool) =
  io.vpnIsActive = isAcitve

proc ipaddr*(device: var Device, ipaddr: string): Result[void, string] =
  if ipaddr.isValidIp4("local"):
    device.ipaddr = ipaddr
    result.ok

  result.err "Invalid ip address"

proc isMAC*(mac: string): bool =
  var separate: char

  if mac.count(':') == 5: separate = ':'
  elif mac.count('-') == 5: separate = '-'
  else: return

  let columns = mac.split(separate)
  if columns.len == 6:
    for s in columns:
      if s.len == 2:
        if (s[0] notin HexDigits) or
           (s[1] notin HexDigits):
          return
    return true

proc macaddr*(device: var Device, macaddr: string): Result[void, string] =
  if macaddr.isMAC:
    device.macaddr = macaddr
    result.ok

  result.err "Invalid MAC address"

proc signal*(device: var Device, signal: string): Result[void, string] =
  device.signal = signal

proc add*(devices: var Devices, device: Device) =
  devices.devs.add device

proc restartDhcpServer*() =
  const cmd = "sudo systemctl restart isc-dhcp-server"
  discard execCmd(cmd)
  
proc refreshDhclient*() =
  const cmd = "sudo dhclient -r"
  discard execCmd(cmd)

proc ifup*(iface: IfaceKind) =
  const cmd = "sudo ifup "
  discard execCmd(cmd & $iface)

proc ifdown*(iface: IfaceKind) =
  const cmd = "sudo ifdown "
  discard execCmd(cmd & $iface)

proc flush*(iface: IfaceKind) =
  const cmd = "ip addr flush dev "
  discard execCmd(cmd & $iface)

proc ifaceExists*(iface: IfaceKind): bool =
  const cmd = "ip link"
  let o = execCmdEx(cmd).output
  for line in o.splitLines():
    if line.contains($iface):
      return true
  
proc hasStaticIp*(iface: IfaceKind): bool =
  const cmd = "sudo ip addr show "
  let ret = execCmdEx(cmd & $iface).output
  for line in ret.splitLines:
    if line.startsWith(re"^(\s|\t){0,4}inet"):
      return true

proc isStateup*(iface: IfaceKind): bool =
  let cmd = execCmdEx("ip link").output
  for v in cmd.splitLines():
    if v.contains($iface):
      if v.contains("state UP"):
        return true

proc isRouter*(iface: IfaceKind): bool =
  let cmd = execCmdEx("ip addr show " & $iface).output
  case iface:
  of wlan0, wlan1:
    if cmd.contains("192.168.42.1"):
      return true

  of eth0, eth1:
    if cmd.contains("192.168.43.1"):
      return true

  else: return

proc dhclientWork*(iface: IfaceKind): bool =
  const prefix =  "ps -ax | grep \"[d]hclient."
  let
    cmd = prefix & $iface & "\""
    ps = execCmdEx(cmd).output
  if ps.len != 0:
    return true

proc parseRoute(str: string): tuple[inputIo, outputIo, tunIo: string] =
  let lines = str.splitLines()
  for v in lines:
    let vv = v.splitwhitespace()
    if vv[0] == "default":
      result.inputIo = vv[7]

proc parseCpuinfo(source, kind: string): string =
  case kind
  of "architecture":
    let lines = source.splitLines
    for v in lines:
      if v.match(re"model name.*"):
        result = v.split(":")[1]
  of "kernelVersion":
    return source.splitWhitespace[2]
  of "model":
    let lines = source.splitLines
    for v in lines:
      if v.match(re"Model.*"):
        result = v.split(":")[1]

const
  procPath = "/proc"
  versionPath = procPath / "version"
  cpuinfoPath = procPath / "cpuinfo"
proc getSystemInfo*(): SystemInfo = 

  try:
    let
      version = readFile(versionPath)
      cpuinfo = readFile(cpuinfoPath)

    result = SystemInfo(
      kernelVersion: version.parseCpuinfo("kernelVersion"),
      model: cpuinfo.parseCpuinfo("model"),
      architecture: cpuinfo.parseCpuinfo("architecture")
    )

  except IOError: return

proc getRpiModel*(): Future[string] {.async.} =
  let
    cpuinfo = readFile(cpuinfoPath)
    lines = cpuinfo.splitLines
  for v in lines:
    if v.match(re"Model.*"):
      result = v.split(":")[1]

proc eraseLogs*(): Future[Result[void, string]] {.async.} =
  const find = "sudo find /var/log -type f"
  try:
    let 
      logs = execCmdEx(find)
      log = split(logs.output, "\n")
    for i, v in log:
      echo "sudo rm " & v
      let _ = execCmd(&"sudo rm " & $v)
      let _ = execCmd("sleep 1")
    discard execShellCmd("sudo rm /home/torbox/.bash_hitstory; sudo histroy -c")
    result.ok
  except Exception:
    result.err "failure"

proc getIO*(): Future[IO] {.async.} =
  var result = IO.new
  const routeCmd = "sudo timeout 5 sudo route"
  let
    routeRes = execCmdEx(routeCmd)
  if routeRes.exitCode != 0:
    return
  let lines = routeRes.output.splitLines()
  try:
    for v in lines:
      let vv = v.splitWhitespace()
      case vv[0]
      of "default":
        let iface = vv[^1].parseIfaceKind()
        if iface.isSome:
          internet(result, iface.get)
      of "192.168.42.0":
        let iface = vv[^1].parseIfaceKind()
        if iface.isSome:
          discard hostap(result, iface.get)
      of "tun0":
        vpn(result, true)

  except: return

# proc hasVpn*(): Future[bool] {.async.} =

proc changePasswd*(current, `new`, renew: string; username: string = "torbox"): Future[Result[void, string]] {.async.} =
  let
    cmdPasswd = &"(echo \"{current}\"; sleep 1; echo \"{`new`}\"; sleep 1; echo \"{renew}\") | passwd {username} >/dev/null 2>&1"
    cmdCode = execCmd(cmdPasswd)
  if cmdCode == 0:
    result.ok

proc getDeviceSignal*(iface: IfaceKind): Future[OrderedTable[string, string]] {.async.} =
  let
    iw = &"iw dev {$iface} station dump"
    iwOut= execCmdEx(iw).output

  if iwOut.len > 0:
    let lines = iwOut.splitLines()

    for i, line in lines:
      if line.startsWith("Station"):
        # sts.add i
                    #signal
        var macaddr, _: string
        let splitted = line.splitWhitespace(maxsplit=2)
        macaddr = splitted[1]

        for j in (i + 1).. (lines.len - 1):
          if lines[j].startsWith(re"\s.*signal:"):
            echo i, lines[j]
            let splitted = lines[j].split("\t", maxsplit=2)
            result[macaddr] = splitted[2]
            break

proc getDevices*(iface: IfaceKind): Future[Devices] {.async.} = 
  let
    cmd = &"arp -i {$iface}"
    arp = execCmdEx(cmd).output
    iw = waitFor getDeviceSignal(iface)
    
  if arp.len > 0:
    for line in arp.splitLines():
      if line.startsWith("Address"):
        continue

      elif line.len > 0:
        let splitted = line.splitWhitespace()
        var device = Device.new
        discard ipaddr(device, splitted[0])
        discard macaddr(device, splitted[2])
        discard signal(device, iw.getOrDefault(splitted[2]))
        result.add(device)
        # result.add (macaddr: [2], ipaddr: parsed[0], signal: iw.getOrDefault(parsed[2]))