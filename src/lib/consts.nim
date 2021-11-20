import std / os

const
  model3* = "Raspberry Pi 3 Model B Rev"
  torrc* = "/etc" / "tor" / "torrc"
  torrcBak* = "/etc" / "tor" / "torrc.bak"
  tmpTorrc* = "/tmp" / "torrc.tmp"
  runfile* = "/home" / "torbox" / "torbox" / "run" / "torbox.run"
  hostapd* = "/etc" / "hostapd" / "hostapd.conf"
  hostapdBak* = "/etc" / "hostapd" / "hostapd.conf.tbx"
  crda* = "/etc" / "default" / "crda"
  torlog* = "/var" / "log" / "tor" / "notices.log"