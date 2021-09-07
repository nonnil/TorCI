import asyncdispatch
import os
import re
import strutils

const torrcPath = "/etc" / "tor" / "torrc"

# This function deactivates the bridge relay.
proc deactivateBridgeRelay*() =
  try:
    let
      torrc = readFile(torrcPath)
      bridge = torrc.findAll(re"BridgeRelay.\d+")[0]
    when defined(debugCi):
      echo "BridgeRelay in Torrc: ", bridge
    if bridge == "BridgeRelay 1":
      let
        orPort = torrc.findAll(re"^ORPort.*")[0].splitWhitespace()[1]
        obfs4Port = torrc.findAll(re"^ServerTransportListenAddr.*")[0].split(":")[1]
      var nTorrc: string
      nTorrc = torrc.multiReplace(@[
        (re"BridgeRelay", "#BridgeRelay"),
        (re"ORPort", "#ORPort"),
        (re"ExtORPort", "#ExtORPort"),
        (re"ServerTransportPlugin", "#ServerTransportPlugin"), 
        (re"ServerTransportListenAddr", "#ServerTransportListenAddr"),
        (re"ContactInfo", "#ContactInfo"),
        (re"Nickname", "#Nickname")
      ])
      discard execShellCmd("sudo iptables -D INPUT -p tcp --dport $sORPORT -j ACCEPT")
      discard execShellCmd("sudo iptables -D INPUT -p tcp --dport $sOBFS4PORT -j ACCEPT")
  except:
    return