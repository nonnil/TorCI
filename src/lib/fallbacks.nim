import os, osproc, re, strutils, strformat, logging
import asyncdispatch
import ".." / [types]
import sys, hostAp
from consts import hostapd, hostapdBak

proc hostapdFallback*() {.async.} =
  try:
    echo("Start hostapd fallback")
    if isRouter(wlan1):
      echo($wlan1 & " is router")
      var f = readFile hostapd
      f = f.replace("interface=wlan0", "interface=wlan1")
      writeFile hostapd, f

    restartService("hostapd")

    if isRouter(wlan1):
      echo($wlan1 & " is router")
      var f = readFile hostapd
      f = f.replace("interface=wlan1", "interface=wlan0")
      writeFile hostapd, f

    let isActive = waitFor getHostApStatus()

    if not isActive:
      echo("hostapd is not active")
      copyFile hostapdBak, hostapd

      if hasStaticIp(wlan1):
        echo("wlan1 has static ip")
        var f = readFile hostapd
        f = f.replace("interface=wlan0", "interface=wlan0")
        writeFile hostapd, f

      restartService("hostapd")

      if hasStaticIp(wlan1):
        echo("wlan1 has static ip")
        var f = readFile hostapd
        f = f.replace("interface=wlan1", "interface=wlan0")
        writeFile hostapd, f
    echo("end hostapd fallback")
      
  except:
    return

proc hostapdFallbackKomplex*(wlan, eth: IfaceKind) =
  const rPath = "/etc" / "network" / "interfaces"
  let lPath = getHomeDir() / "torbox" / "etc" / "network" / &"interfaces.{$wlan}{$eth}"

  if (not fileExists(lPath)) or (not fileExists(rPath)):
    return

  var
    newWlan: IfaceKind
    newEth: IfaceKind
    downedWlan: bool
    downedEth: bool
    cmd: string

  # wlan and eth are clients - newWlan and newEth are potential Internet sources
  newWlan = if wlan == wlan1: wlan0 else: wlan1
  newEth = if eth == eth1: eth0 else: eth1
  
  # First, we have to shutdown the interface with running dhcpclients, before we copy the interfaces file
  if dhclientWork(wlan):
    refreshdhclient()
    ifdown(wlan)
    downedwlan = true

  if dhclientWork(eth):
    refreshdhclient()
    ifdown(eth)
    downedeth = true
  
  copyfile(lpath, rpath)
  
  if downedwlan:
    ifup(wlan)
    downedWlan = false

  if downedEth:
    ifup(eth)
    downedEth = false
  
  # Is wlan ready?
  # If wlan0 or wlan1 doesn't have an IP address then we have to do something about it!
  if not hasStaticIp(wlan):
    ifdown(wlan)
    # Cannot be run in the background because then it jumps into the next if-then-else clause (still missing IP)
    ifup(wlan)
    
  # If wlan0 or wlan1 is not acting as AP then we have to do something about it!
  let conf = waitFor getHostApConf()
  if conf.iface == unkwnIface:
    try:
      var f = readFile(hostapd)
      f = f.replace(re"interface=.*", "interface=" & $wlan)
      restartService("hostapd")
      sleep 5
      if not waitFor getHostApStatus():
        f = f.multiReplace(
          @[
            ("hw_mode=a", "hw_mode=g"),
            ("channel=.*", "channel=6"),
            ("ht_capab=[HT40-][HT40+][SHORT-GI-20][SHORT-GI-40][DSSS_CCK-40]", "#ht_capab=[HT40-][HT40+][SHORT-GI-20][SHORT-GI-40][DSSS_CCK-40]"),
            ("vht_oper_chwidth=1", "#vht_oper_chwidth=1"),
            ("vht_oper_centr_freq_seg0_idx=42", "#vht_oper_centr_freq_seg0_idx=42")
          ]
        )
      writeFile(hostapd, f)
      restartService("hostapd")

    except:
      return

  # Is eth ready?
  if isStateup(eth):
    if not isRouter(eth):
      ifdown(eth)
      ifup(eth)

  else:
    ifdown(eth)
    ifup(eth)
  
  # Is newWlan ready?
  # Because it is a possible Internet source, the Interface should be up, but
  # the IP adress shouldn't be 192.168.42.1 or 192.168.43.1
  if isStateup(newWlan):

    if not hasStaticIp(newWlan):
      ifdown(newWlan)
      ifup(newWlan)

    if isRouter(newWlan):
      ifdown(newWlan)
      ifup(newWlan)

  else:
    ifdown(newWlan)
    flush(newWlan)
    ifup(newWlan)
  
  # Is newEth ready?
  # Because it is a possible Internet source, the Interface should be up, but
  # the IP adress shouldn't be 192.168.42.1 or 192.168.43.1
  if isStateup(newEth):

    if not hasStaticIp(newEth):
      ifdown(newEth)
      ifup(newEth)

    if isRouter(newEth):
      ifdown(newEth)
      ifup(newEth)

  else:
    ifdown(newEth)
    flush(newEth)
    ifup(newEth)
  
  # This last part resets the dhcp server and opens the iptables to access TorBox
  # This fundtion has to be used after an ifup command
  # Important: the right iptables rules to use Tor have to configured afterward
  restartDhcpServer()
  discard execCmd("sudo /sbin/iptables -F")
  discard execCmd("sudo /sbin/iptables -t nat -F")
  discard execCmd("sudo /sbin/iptables -P FORWARD DROP")
  discard execCmd("sudo /sbin/iptables -P INPUT ACCEPT")
  discard execCmd("sudo /sbin/iptables -P OUTPUT ACCEPT")