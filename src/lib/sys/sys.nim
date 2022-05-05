import std / [
  asyncdispatch, strutils, strformat,
  re, tables, os, osproc, options
]
import results
import iface

type
  SystemInfo* = ref object
    architecture*: string
    kernelVersion*: string
    model*: string
    uptime*: int
    localtime*: int
    torboxVer*: string

  IO* = ref object
    internet*, hostap*: Option[IfaceKind]
    vpnIsActive*: bool

  Devices* = seq[Device]

  Device* = ref object
    macaddr*: string
    ipaddr*: string
    signal*: string

proc hostap*(io: var IO, iface: IfaceKind): Result[void, string] =
  case iface
  of wlan0, wlan1:
    io.hostap = some iface
    result.ok
  
  else:
    result.err "should be set to wireless interface"

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

# proc macaddr*(device: var Device, macaddr: string): Result[void, string] =
#   if macaddr.isMAC:
#     device.macaddr = macaddr
#     result.ok

#   result.err "Invalid MAC address"

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

proc getSystemInfo*(): Future[Result[SystemInfo, string]] {.async.} = 
  try:
    let
      version = readFile(versionPath)
      cpuinfo = readFile(cpuinfoPath)

    result = ok SystemInfo(
      kernelVersion: version.parseCpuinfo("kernelVersion"),
      model: cpuinfo.parseCpuinfo("model"),
      architecture: cpuinfo.parseCpuinfo("architecture")
    )

  except IOError as e: return err(e.msg)

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

proc getIO*(): Future[Result[IO, string]] {.async.} =
  var ret = IO.new

  const routeCmd = "sudo timeout 5 sudo route"

  let
    routeRes = execCmdEx(routeCmd)

  if routeRes.exitCode != 0:
    return err("failed \"route\" command")

  let lines = routeRes.output.splitLines()
  try:
    for v in lines:
      let vv = v.splitWhitespace()
      case vv[0]
      of "default":
        let iface = vv[^1].parseIfaceKind()
        if iface.isSome:
          ret.internet = iface

      of "192.168.42.0":
        let iface = vv[^1].parseIfaceKind()
        if iface.isSome:
          ret.hostap = iface

      of "tun0":
        ret.vpnIsActive = true
    
    return ok(ret)

  except IOError as e: return err(e.msg) 

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
        var device = new(Device)
        device.ipaddr = splitted[0]
        device.macaddr = splitted[2]
        device.signal = iw.getOrDefault(splitted[2])
        result.add(device)
        # result.add (macaddr: [2], ipaddr: parsed[0], signal: iw.getOrDefault(parsed[2]))