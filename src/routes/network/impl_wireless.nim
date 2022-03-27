import std / [ options, tables, asyncdispatch ]
import results
import jester
import ".." / [ network_impl ]
import ".." / ".." / [ types, notice, settings ]
import ".." / ".." / views / [ temp, network ]
import ".." / ".." / lib / [ sys, session, hostap ]

proc hostapConf*(request: jester.Request): Future[string] {.async.} =
  var 
    hostap: HostAp = HostAp.new
    conf = await getHostApConf()
    iface = conf.getIface
    devs = await getDevices(iface.get)
  let rpiModel = await getRpiModel()
  return renderNode(renderHostApPane(hostap, rpiModel, devs), request, request.getUserName, "Wireless", netTab())

proc doConfigHostap*(request: jester.Request): Future[Option[string]] {.async.} =
  let
    band = if sysInfo.model == hostap.model3: "g"
           else: request.formData.getOrDefault("band").body
    channel = request.formData.getOrDefault("channel").body
    ssid = request.formData.getOrDefault("ssid").body
    cloak = request.formData.getOrDefault("ssidCloak").body
    password = request.formData.getOrDefault("password").body
  
  var
    notifies: Notifies = new()
    hostapConf: HostApConf = HostApConf.new

  block:
    let ret = hostapConf.ssid ssid
    if ret.isErr: notifies.add failure, ret.error

  block:
    let ret = hostapConf.band band
    if ret.isErr: notifies.add failure, ret.error

  block:
    let ret = hostapConf.channel channel
    if ret.isErr: notifies.add failure, ret.error

  block:
    hostapConf.cloak if cloak == "1": true else: false

  block:
    let ret = hostapConf.password password
    if ret.isErr: notifies.add failure, ret.error

  hostapConf.write()

  if notifies.isEmpty:
    notifies.add success, "configuration successful. please restart the access point to apply the changes"

  var 
    hostap: HostAp = HostAp.new
    conf = await getHostApConf()
    devs = await getDevices(conf.getIface.get)
    rpiModel = await getRpiModel()

  let isActive = await hostapdIsActive()
  hostap.active isActive

  # resp renderNode(renderHostApPane(hostap, sysInfo, devs), request, request.getUserName, "Wireless", tab, notifies=notifies)
  let ret = renderNode(renderHostApPane(hostap, rpiModel, devs), request, request.getUserName, "Wireless", netTab(), notifies=notifies)
  return some(ret)