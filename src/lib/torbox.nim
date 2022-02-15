import os, osproc, asyncdispatch
import re, strutils, strformat
import sys
import ".." / [types, utils]
import nativesockets
import torcfg

const
  iptable = "/sbin" / "iptables"
  modprobe = "/sbin" / "modprobe"
  dnsprog = "dnsmasq"
  runfile* = "/home" / "torbox" / "torbox" / "run" / "torbox.run"

# getTorboxVersion for test
proc getTorboxVersion*(hname: var string): string {.test.} =
  if hname.match(re"TorBox(\d){3}"):
    hname.delete(0..5)
    result = hname.insertSep('.', 1)

proc getTorboxVersion*(): string =
  var hname = getHostname()
  if hname.match(re"TorBox(\d){3}"):
    hname.delete(0, 5)
    result = hname.insertSep('.', 1)

proc setCaptive*(serverIface, clientWln, clientEth: IfaceKind) =
  
  # PREPARATIONS
  startService(dnsprog)
  discard execCmd(iptable & " -F")
  discard execCmd(iptable & " -F -t nat")
  discard execCmd(iptable & " -X")
  discard execCmd(iptable & " -P INPUT ACCEPT")
  discard execCmd(iptable & " -P OUTPUT ACCEPT")
  discard execCmd(iptable & " -P FORWARD ACCEPT")
  discard execCmd(modprobe & " ip_conntrack")
  discard execCmd(modprobe & " iptable_nat")
  discard execCmd(modprobe & " ip_conntrack_ftp")
  discard execCmd(modprobe & " ip_nat_ftp")
  
  # NAT rules
  # We will forward all the network traffic to the captive portal in order to log in
  discard execCmd(iptable & &" -t nat -A POSTROUTING -o {$serverIface} -j MASQUERADE")
  discard execCmd(iptable & &" -A FORWARD -i {$serverIface} -o {$clientWln} -m state --state RELATED,ESTABLISHED -j ACCEPT")
  discard execCmd(iptable & &" -A FORWARD -i {$serverIface} -o {$clientEth} -m state --state RELATED,ESTABLISHED -j ACCEPT")
  discard execCmd(iptable & &" -A FORWARD -i {$clientWln} -o {$serverIface} -j ACCEPT")
  discard execCmd(iptable & &" -A FORWARD -i {$clientEth} -o {$serverIface} -j ACCEPT")

  stopService(dnsprog)

proc setInterface*(serverIface, clientWln, clientEth: IfaceKind) =
  const
    wlnIp = "192.168.42.1"
    ethIp = "192.168.43.1"
    intrnt1 = wlnIp & "1/8"
    intrnt2 = wlnIp & "2/8"
  
  # PREPARATIONS
  discard execCmd(iptable & " -F")
  discard execCmd(iptable & " -F -t nat")
  discard execCmd(iptable & " -X")
  discard execCmd(iptable & " -P INPUT DROP")
  discard execCmd(iptable & " -P OUTPUT ACCEPT")
  discard execCmd(iptable & " -P FORWARD DROP")
  discard execCmd(modprobe & " ip_conntrack")
  discard execCmd(modprobe & " iptable_nat")
  discard execCmd(modprobe & " ip_conntrack_ftp")
  discard execCmd(modprobe & " ip_nat_ftp")
  
  # INPUT chain
  # State tracking rules
  discard execCmd(iptable & " -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT")
  discard execCmd(iptable & " -A INPUT -m state --state INVALID -j DROP")
  
  # Anti-spoofing rules
  discard execCmd(iptable & &" -A INPUT -i {$clientWln} ! -s {$intrnt1} -j LOG --log-prefix \"SPOOFED PKT \"")
  discard execCmd(iptable & &" -A INPUT -i {$clientEth} ! -s {$intrnt2} -j LOG --log-prefix \"SPOOFED PKT \"")
  discard execCmd(iptable & &" -A INPUT -i {$clientWln} ! -s {$intrnt1} -j DROP")
  discard execCmd(iptable & &" -A INPUT -i {$clientEth} ! -s {$intrnt2} -j DROP")

  # Let packages to the localhost
  discard execCmd(iptable & " -A INPUT -i lo -j ACCEPT")
  
  # Open access from the internal network (usually my own devices)
  discard execCmd(iptable & &" -A INPUT -i {$clientWln} -j ACCEPT")
  discard execCmd(iptable & &" -A INPUT -i {$clientEth} -j ACCEPT")
  
  # Allow ICMP Ping
  discard execCmd(iptable & " -A INPUT -p icmp --icmp-type echo-request -j ACCEPT")
  discard execCmd(iptable & " -A INPUT -p icmp --icmp-type echo-reply -j ACCEPT")
  
  # OUTPUT chain
  # Avoid Linux kernel transproxy packet leak. See: https://lists.torproject.org/pipermail/tor-talk/2014-March/032507.html
  discard execCmd(iptable & " -A OUTPUT -m conntrack --ctstate INVALID -j DROP")
  discard execCmd(iptable & " -A OUTPUT -m state --state INVALID -j DROP")
  discard execCmd(iptable & " -A OUTPUT ! -o lo ! -d 127.0.0.1 ! -s 127.0.0.1 -p tcp -m tcp --tcp-flags ACK,RST ACK,RST -j DROP")
  # I will be absolutely sure that no DNS requests are done outside Tor --> this will be visible in the log (but we don't block it yet)
  discard execCmd(iptable & &" -A OUTPUT -o {$serverIface} -p tcp --dport 53 -j LOG --log-prefix \"SSH SHELL DNS-REQUEST TCP\" --log-ip-options --log-tcp-options")
  discard execCmd(iptable & &" -A OUTPUT -o {$serverIface} -p udp --dport 53 -j LOG --log-prefix \"SSH SHELL DNS-REQUEST UDP\" --log-ip-options")
  # No other restrictions for OUTPUT
  
  # FORWARD chain
  # State tracking rules
  discard execCmd(iptable & " -A FORWARD -m state --state INVALID -j DROP")
  # Allow ICMP Ping
  discard execCmd(iptable & " -A FORWARD -p icmp --icmp-type echo-request -j ACCEPT")
  discard execCmd(iptable & " -A FORWARD -p icmp --icmp-type echo-reply -j ACCEPT")
  
  # NAT rules
  # Access on the box's own IP should be granted (only TCP)
  discard execCmd(iptable & &" -t nat -A PREROUTING -i {$clientWln} -d {$wlnIp} -p tcp -j REDIRECT")
  discard execCmd(iptable & &" -t nat -A PREROUTING -i {$clientEth} -d {$ethIp} -p tcp -j REDIRECT")
  # TCP/UDP/DNS over Tor
  discard execCmd(iptable & &" -t nat -A PREROUTING -i {$clientWln} -p tcp -j REDIRECT --to-ports 9040")
  discard execCmd(iptable & &" -t nat -A PREROUTING -i {$clientEth} -p tcp -j REDIRECT --to-ports 9040")
  discard execCmd(iptable & &" -t nat -A PREROUTING -i {$clientWln} -p udp --dport 53 -j REDIRECT --to-ports 9053")
  discard execCmd(iptable & &" -t nat -A PREROUTING -i {$clientEth} -p udp --dport 53 -j REDIRECT --to-ports 9053")
  discard execCmd(iptable & &" -t nat -A PREROUTING -i {$clientWln} -p udp -j REDIRECT --to-ports 9040")
  discard execCmd(iptable & &" -t nat -A PREROUTING -i {$clientEth} -p udp -j REDIRECT --to-ports 9040")
  # Masquerading
  discard execCmd(iptable & &" -t nat -A POSTROUTING -o {$serverIface} -j MASQUERADE")
  
  let runfileData = readFile(runfile)
  let lines = runfileData.splitLines()
  for line in lines:
    # SSH access through Internet
    if line.startsWith("SSH_FROM_INTERNET=1"):
      discard execCmd(iptable & " -A INPUT -p tcp --dport 22 -j ACCEPT")

    elif line.startsWith(re"SSH_FROM_INTERNET=.*"):
      discard execCmd(iptable & " -D INPUT -p tcp --dport 22 -j ACCEPT")

    # HTTP plain text traffic blocker 
    elif line.startsWith("BLOCK_HTTP=1"):
      discard execCmd(iptable & " -t nat -I PREROUTING 1 -p tcp --dport 80 -j LOG --log-prefix \"HTTP-REQUEST TCP \" --log-ip-options --log-tcp-options")
      discard execCmd(iptable & " -t nat -I PREROUTING 2 -p udp --dport 80 -j LOG --log-prefix \"HTTP-REQUEST UDP \" --log-ip-options")
      discard execCmd(iptable & " -t nat -I PREROUTING 3 -p tcp --dport 80 -j DNAT --to-destination 0.0.0.0")
      discard execCmd(iptable & " -t nat -I PREROUTING 4 -p udp --dport 80 -j DNAT --to-destination 0.0.0.0")

    elif line.startsWith(re"BLOCK_HTTP=.*"):
      discard execCmd(iptable & " -t nat -D PREROUTING -p tcp --dport 80 -j LOG --log-prefix \"HTTP-REQUEST TCP \" --log-ip-options --log-tcp-options")
      discard execCmd(iptable & " -t nat -D PREROUTING -p udp --dport 80 -j LOG --log-prefix \"HTTP-REQUEST UDP \" --log-ip-options")
      discard execCmd(iptable & " -t nat -D PREROUTING -p tcp --dport 80 -j DNAT --to-destination 0.0.0.0")
      discard execCmd(iptable & " -t nat -D PREROUTING -p udp --dport 80 -j DNAT --to-destination 0.0.0.0")
  
  # FINISH
  stopService("tor")
  restartService("tor")

proc saveIptables*() =
  discard execCmd("sudo sh -c \"iptables-save > /etc/iptables.ipv4.nat\"")

proc torControlPortAccess(): bool =
  const s = "TOR_CONTROL_PORT_ACCESS=1"
  try:
    let f = readFile(runFile)
    for v in f.splitLines():
      if v.startsWith(s):
        return true
  except: return

proc editTorrc*(internetIface, clientWln, clientEth: IfaceKind) =
  if not fileExists(torrc):
    return

  var
    torrcFile = readFile(torrc)
    runfileFile = readFile(runfile)

  let access = torControlPortAccess()

  var
    # lWln = if access: "#ControlPort 192.168.42.1:9051" else: "ControlPort 192.168.42.1:9051"
    # rWln = if access: "ControlPort 192.168.42.1:9051" else: "#ControlPort 192.168.42.1:9051"
    # lEth = if access: "#ControlPort 192.168.43.1:9051" else: "ControlPort 192.168.43.1:9051"
    # rEth = if access: "ControlPort 192.168.43.1:9051" else: "#ControlPort 192.168.43.1:9051"

    (lWln, rWln, lEth, rEth) = if access: (
      "#ControlPort 192.168.42.1:9051",
      "ControlPort 192.168.42.1:9051",
      "#ControlPort 192.168.43.1:9051",
      "ControlPort 192.168.43.1:9051"
    )
    else: (
      "ControlPort 192.168.42.1:9051",
      "#ControlPort 192.168.42.1:9051",
      "ControlPort 192.168.43.1:9051",
      "#ControlPort 192.168.42.1:9051"
    )
  
  let
    activeWln: bool = if isStateup(clientWln): isRouter(clientWln) else: false
    activeEth: bool = if isStateup(clientEth): isRouter(clientEth) else: false
    
  if activeWln and activeEth:
    torrcFile = torrcFile.multiReplace(
      @[
        (re"#TransPort 192.168.42.1:9040", "TransPort 192.168.42.1:9040"),
        (re"#DNSPort 192.168.42.1:9053", "DNSPort 192.168.42.1:9053"),
        (re"#SocksPort 192.168.42.1:9050", "SocksPort 192.168.42.1:9050"),
        (re"#SocksPort 192.168.42.1:9052", "SocksPort 192.168.42.1:9052"),
        (re lWln, rWln),
        (re"#TransPort 192.168.43.1:9040", "TransPort 192.168.43.1:9040"),
        (re"#DNSPort 192.168.43.1:9053", "DNSPort 192.168.43.1:9053"),
        (re"#SocksPort 192.168.43.1:9050", "SocksPort 192.168.43.1:9050"),
        (re"#SocksPort 192.168.43.1:9052", "SocksPort 192.168.43.1:9052"),
        (re lEth, rEth)
      ]
    )

    runfileFile = runfileFile.multiReplace(
      @[
        (re"INTERNET_IFACE=.*", "INTERNET_IFACE=" & $internetIface),
        (re"CLIENT_IFACE=.*", &"CLIENT_IFACE={clientWln} {clientEth}")
      ]
    )
  
  elif not activeWln and activeEth:
    lWln = "ControlPort 192.168.42.1:9051"
    rWln = "#ControlPort 192.168.42.1:9051"

    torrcFile = torrcFile.multiReplace(
      @[
        (re"TransPort 192.168.42.1:9040", "#TransPort 192.168.42.1:9040"),
        (re"DNSPort 192.168.42.1:9053", "#DNSPort 192.168.42.1:9053"),
        (re"SocksPort 192.168.42.1:9050", "#SocksPort 192.168.42.1:9050"),
        (re"SocksPort 192.168.42.1:9052", "#SocksPort 192.168.42.1:9052"),
        (re lWln, rWln),
        (re"#TransPort 192.168.43.1:9040", "TransPort 192.168.43.1:9040"),
        (re"#DNSPort 192.168.43.1:9053", "DNSPort 192.168.43.1:9053"),
        (re"#SocksPort 192.168.43.1:9050", "SocksPort 192.168.43.1:9050"),
        (re"#SocksPort 192.168.43.1:9052", "SocksPort 193.168.43.1:9052"),
        # (re"ControlPort 192.168.42.1:9051", "#ControlPort 192.168.42.1:9051"),
        (re lEth, rEth)
      ]
    )

    runfileFile = runfileFile.multiReplace(
      @[
        (re"INTERNET_IFACE=.*", "INTERNET_IFACE=" & $internetIface),
        (re"CLIENT_IFACE=.*", &"CLIENT_IFACE={clientEth}")
      ]
    )

  else:
    lEth = "ControlPort 192.168.43.1:9051"
    rEth = "#ControlPort 192.168.43.1:9051"

    torrcFile = torrcFile.multiReplace(
      @[
        (re"#TransPort 192.168.42.1:9040", "TransPort 192.168.42.1:9040"),
        (re"#DNSPort 192.168.42.1:9053", "DNSPort 193.168.42.1:9053"),
        (re"#SocksPort 192.168.42.1:9050", "SocksPort 192.168.42.1:9050"),
        (re"#SocksPort 192.168.42.1:9052", "SocksPort 192.168.42.1:9052"),
        (re lWln, rWln),
        (re"TransPort 192.168.43.1:9040", "#TransPort 192.168.43.1:9040"),
        (re"DNSPort 192.168.43.1:9053", "#DNSPort 192.168.43.1:9053"),
        (re"SocksPort 192.168.43.1:9050", "#SocksPort 192.168.43.1:9050"),
        (re"SocksPort 192.168.43.1:9052", "#SocksPort 192.168.43.1:9052"),
        (re lEth, rEth)
      ]
    )

    runfileFile = runfileFile.multiReplace(
      @[
        (re"INTERNET_IFACE=.*", "INTERNET_IFACE=" & $internetIface),
        (re"CLIENT_IFACE=.*", &"CLIENT_IFACE={clientWln}")
      ]
    )

  torrc.writeFile(torrcFile)
  runfile.writeFile(runfileFile)

# proc assignIface*(serverIface: IfaceKind, isCaptive: bool) Future[bool] {.async.} =

#   var clientWln, clientEth: IfaceKind
#     # clientEth: IfaceKind

#   case serverIface

#   of eth0:
#     clientWln = wlan0
#     clientEth = eth1

#   of wlan1, usb0, eth1:
#     clientWln = wlan0
#     clientEth = eth0
  
#   of wlan0:
#     clientWln = wlan1
#     clientEth = eth0

#   else: return

#   editTorrc(serverIface, clientWln, clientEth)
#   restartDhcpServer()
#   # setCaptive(serverIface, clientWln, clientEth)
#   setInterface(serverIface, clientWln, clientEth, isCaptive)