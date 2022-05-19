import std / [
  asyncdispatch, os, osproc,
  re,
  strutils, strformat,
  tables, options
]
import results, resultsutils
import jsony
import iface

const
  procPath = "/proc"
  cpuinfoPath = procPath / "cpuinfo"

type
  SystemInfo* = ref object
    cpu: CpuInfo
    # model*: string
    # architecture*: string
    kernelVersion: string
    uptime: int
    localtime: int
    torboxVer: string

  IoInfo* = ref object
    internet, hostap: Option[IfaceKind]
    vpnIsActive*: bool

  Devices* = ref object
    list: seq[Device]

  Device* = ref object
    macaddr*: string
    ipaddr*: string
    signal*: string
  
  CpuInfo* = ref object
    model, architecture: string

# methods for SystemInfo
proc default*(_: typedesc[SystemInfo]): SystemInfo =
  result = SystemInfo.new()
  result.cpu = CpuInfo.new()

# proc default*(_: typedesc[Devices]): Devices =
#   new Devices

method cpu*(self: SystemInfo): CpuInfo {.base.} =
  self.cpu

method kernelVersion*(self: SystemInfo): string {.base.} =
  self.kernelVersion

method uptime*(self: SystemInfo): int {.base.} =
  self.uptime

method localtime*(self: SystemInfo): int {.base.} =
  self.localtime

method torboxVersion*(self: SystemInfo): string {.base.} =
  self.torboxVer

method model*(self: SystemInfo): string {.base.} =
  self.cpu.model

method architecture*(self: SystemInfo): string {.base.} =
  self.cpu.architecture

# methods for CpuInfo
method model*(self: CpuInfo): string {.base.} =
  self.model

method architecture*(self: CpuInfo): string {.base.} =
  self.architecture

# methods for IoInfo
method internet*(self: IoInfo): Option[IfaceKind] {.base.} =
  self.internet

method hostap*(self: IoInfo): Option[IfaceKind] {.base.} =
  self.hostap

method vpnIsActive*(self: IoInfo): bool {.base.} =
  self.vpnIsActive

# Devices
method list*(self: Devices): seq[Device] {.base.} =
  self.list

proc hostap*(io: var IoInfo, iface: IfaceKind): Result[void, string] =
  case iface
  of wlan0, wlan1:
    io.hostap = some iface
    result.ok
  
  else:
    result.err "should be set to wireless interface"

proc newHook*(si: var SystemInfo) =
  si.kernelVersion = "Unknown"
  si.torboxVer = "Unknown"

proc newHook*(cpuInfo: var CpuInfo) =
  cpuInfo.architecture = "Unknown"
  cpuInfo.model = "Unknown"

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
  of "model":
    let lines = source.splitLines
    for v in lines:
      if v.match(re"Model.*"):
        result = v.split(":")[1]

proc getCpuInfo(): Result[CpuInfo, string] =

  func readAsCpuInfo(source: string): CpuInfo =
    # source.splitLines()
    #   filterIt((it.match(re"model name.*") or it.match(re"Model.*")))
    let lines = source.splitLines
    var
      arch: string
      model: string
    for v in lines:
      if v.match(re"model name.*"):
        arch = v.split(":")[1]
      if v.match(re"Model.*"):
        model = v.split(":")[1]
    return CpuInfo(
      architecture: arch,
      model: model
    )

  try:
    let r = readFile(cpuinfoPath)
      .readAsCpuInfo()
    return ok(r)
  except IOError as e: return err(e.msg)
  except OSError as e: return err(e.msg)
    

proc getKernelVersion(): Result[string, string] =
  const versionPath = procPath / "version"

  func parseKernelVersion(source: string): string =
    source.splitWhitespace[2]

  try:
    return ok(readFile(versionPath)
      .parseKernelVersion()
    )
  
  except IOError as e: return err(e.msg)
  except OSError as e: return err(e.msg)
  except ValueError as e: return err(e.msg)

proc getSystemInfo*(): Future[Result[SystemInfo, string]] {.async.} = 
  try:
    var
      cpuInfo: CpuInfo
      kernelVer: string

    match getCpuInfo():
      Ok(ret): cpuInfo = ret
      Err(msg): return err(msg)
    match getKernelVersion():
      Ok(ret): kernelVer = ret
      Err(msg): return err(msg)
    return ok SystemInfo(
      kernelVersion: kernelVer,
      cpu: cpuInfo
    )

  except IOError as e: return err(e.msg)
  except OSError as e: return err(e.msg)

proc getRpiModel*(): Future[Result[string, string]] {.async.} =
  try:
    let
      lines = readFile(cpuinfoPath)
        .splitLines
    for v in lines:
      if v.match(re"Model.*"):
        let model = v.split(":")[1]
        return ok(model)
    
    # let pair: seq[string] = readFile(cpuinfoPath)
    #   .splitLines()
    #   .filter((s: string) -> bool => s.match(re"Model.*"))
    #   .map((s: string) => s.split(':'))
    #   .foldl((s: seq[string]) => s[0])
    # return ok(pair[1])

  except IOError as e: return err(e.msg)
  except OSError as e: return err(e.msg)

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

proc getIoInfo*(): Future[Result[IoInfo, string]] {.async.} =
  var ret = IoInfo.new()

  const routeCmd = "sudo timeout 5 sudo route"

  try:
    let routeRes = execCmdEx(routeCmd)
    if routeRes.exitCode != 0:
      return err("failed \"route\" command")
    let lines = routeRes.output.splitLines()

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
  except OSError as e: return err(e.msg) 
  except ValueError as e: return err(e.msg) 
  except KeyError as e: return err(e.msg)
  except IndexError as e: return err(e.msg)

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

proc getDevices*(iface: IfaceKind): Future[Result[Devices, string]] {.async.} = 
  try:
    let
      cmd = &"arp -i {$iface}"
      arp = execCmdEx(cmd).output
      iw = waitFor getDeviceSignal(iface)
    var ret: Devices
      
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
          ret.list.add(device)
    return ok(ret)
  except OSError as e: return err(e.msg)
  except IOError as e: return err(e.msg)