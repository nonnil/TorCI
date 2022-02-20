import std / [
  asyncdispatch, strutils, strformat,
  re, tables, os, osproc
]
import ".." / [ types ]
import hostap

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

proc getSystemInfo*(): SystemInfo = 
  const
    procDir = "/proc"
    procVersion = procDir / "version"
    procCpuinfo = procDir / "cpuinfo"

  try:
    let
      version = readFile(procVersion)
      cpuinfo = readFile(procCpuinfo)

    result = SystemInfo(
      kernelVersion: version.parseCpuinfo("kernelVersion"),
      model: cpuinfo.parseCpuinfo("model"),
      architecture: cpuinfo.parseCpuinfo("architecture")
    )

  except IOError: return

proc eraseLogs*(): Future[State] {.async.} =
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
    result = success
  except Exception:
    result = failure

proc getActiveIface*(): Future[ActiveIfaceList] {.async.} =
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
        result.input = vv[^1].parseIface
      of "192.168.42.0":
        result.output = vv[^1].parseIface
      of "tun0":
        result.hasVpn = true
  except: return

# proc hasVpn*(): Future[bool] {.async.} =

proc changePasswd*(currentPasswd, newPasswd, rnewPasswd: string; username: string = "torbox"): Future[bool] {.async.} =
  let
    cmdPasswd = &"(echo \"{currentPasswd}\"; sleep 1; echo \"{newPasswd}\"; sleep 1; echo \"{rnewPasswd}\") | passwd {username} >/dev/null 2>&1"
    cmdCode = execCmd(cmdPasswd)
  if cmdCode == 0:
    result = true

proc getDevsSignal*(wlan: IfaceKind): OrderedTable[string, string] =
  let
    iw = &"iw dev {$wlan} station dump"
    iwOut= execCmdEx(iw).output

  if iwOut.len > 0:
    let lines = iwOut.splitLines()

    for i, line in lines:
      if line.startsWith("Station"):
        # sts.add i
        var macaddr, signal: string
        let parsed = line.splitWhitespace(maxsplit=2)
        macaddr = parsed[1]

        for j in (i + 1).. (lines.len - 1):
          if lines[j].startsWith(re"\s.*signal:"):
            echo i, lines[j]
            let parsed = lines[j].split("\t", maxsplit=2)
            result[macaddr] = parsed[2]
            break

proc getConnectedDevs*(wlan: IfaceKind): Future[ConnectedDevs] {.async.} = 
  let
    arp = &"arp -i {$wlan}"
    arpOut = execCmdEx(arp).output
    iw = getDevsSignal(wlan)
    
  if arpOut.len > 0:
    for line in arpOut.splitLines():
      if line.startsWith("Address"):
        continue

      elif line.len > 0:
        let parsed = line.splitWhitespace()
        result.add (macaddr: parsed[2], ipaddr: parsed[0], signal: iw.getOrDefault(parsed[2]))