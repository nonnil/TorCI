import std / options
import results, resultsutils
import jester, karax / [ karaxdsl, vdom]
import ".." / ".." / lib / [ sys, session, hostap ]
import ".." / ".." / [ renderutils, notice ]
import ../ tabs

proc routerWireless*() =
  router wireless:
    template tab(): Tab =
      buildTab:
        "Bridges" = "/net" / "bridges"
        "Interfaces" = "/net" / "interfaces"
        "Wireless" = "/net" / "wireless"

    get "/wireless/@hash":
      loggedIn:
        var 
          hostap: HostAp = HostAp.default()
          # iface = conf.iface
          devs = Devices.default()
          nc = Notifies.default() 
        
        hostap = await getHostAp()
        let
          isModel3 = await rpiIsModel3()
          iface = hostap.conf.iface

        if iface.isSome:
          match await getDevices(iface.get):
            Ok(ret): devs = ret
            Err(msg): nc.add(failure, msg)

        resp: render "Wireless":
          tab: tab
          notice: nc
          container:
            hostap.render(isModel3)
            devs.render()

    get "/wireless":
      loggedIn:
        var 
          hostap: HostAp = HostAp.default()
          # iface = conf.iface
          devs = Devices.default()
          nc = Notifies.default() 
        
        hostap = await getHostAp()
        let
          isModel3 = await rpiIsModel3()
          iface = hostap.conf.iface

        match await getDevices(iface.get):
          Ok(ret): devs = ret
          Err(msg): nc.add(failure, msg)

        resp: render "Wireless":
          tab: tab
          notice: nc
          container:
            hostap.render(isModel3)
            devs.render()

    post "/wireless":
      loggedIn:
        let
          isModel3 = await rpiIsModel3()
          band = if isModel3: "g"
                 else: request.formData.getOrDefault("band").body
          channel = request.formData.getOrDefault("channel").body
          ssid = request.formData.getOrDefault("ssid").body
          cloak = request.formData.getOrDefault("ssidCloak").body
          password = request.formData.getOrDefault("password").body
        
        var
          nc = Notifies.default()
          hostapConf: HostApConf = HostApConf.new

        nc.add(hostapConf.ssid(ssid))
        nc.add(hostapConf.band(band))
        nc.add(hostapConf.channel(channel))
        nc.add(hostapConf.password(password))

        hostapConf.cloak if cloak == "1": true else: false

        hostapConf.write()

        if nc.isEmpty:
          nc.add success, "configuration successful. please restart the access point to apply the changes"

        var 
          hostap: HostAp = HostAp.new()
          conf = await getHostApConf()
          devs = Devices.default()

        match await getDevices(conf.iface.get):
          Ok(ret): devs = ret
          Err(msg): nc.add(failure, msg)

        let isActive = hostapdIsActive()
        hostap.active(isActive)

        # resp renderNode(renderHostApPane(hostap, isModel3, devs), request, request.getUserName, "Wireless", netTab(), notifies=notifies)
        resp: render "Wireless":
          tab: tab
          notice: nc
          container:
            hostap.conf.render(isModel3)
            hostap.status.render()
            devs.render()