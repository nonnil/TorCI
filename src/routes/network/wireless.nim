import std / [ options, sugar ]
import results, resultsutils
import jester
import ".." / [ network_impl ]
import ".." / ".." / lib / [ sys, session, hostap ]
import ".." / ".." / [ notice ]
import ".." / ".." / views / [ temp, network ]

proc routerWireless*() =
  router wireless:
    get "/wireless/@hash":
      loggedIn:
        var 
          hostap: HostAp = HostAp.new
          conf = await getHostApConf()
          iface = conf.getIface
          devs = await getDevices(iface.get)
        let
          isModel3 = await rpiIsModel3()
          isActive = hostapdIsActive()
        hostap.active(isActive)
        resp renderNode(renderHostApPane(hostap, isModel3, devs), request, request.getUserName, "Wireless", netTab())

    get "/wireless":
      loggedIn:
        var 
          hostap: HostAp = HostAp.new
          conf = await getHostApConf()
          iface = conf.getIface
          devs = await getDevices(iface.get)
        let
          isModel3 = await rpiIsModel3()
          isActive = hostapdIsActive()
        hostap.active(isActive)
        resp renderNode(renderHostApPane(hostap, isModel3, devs), request, request.getUserName, "Wireless", netTab())

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
          notifies: Notifies = new()
          hostapConf: HostApConf = HostApConf.new

        notifies.add(hostapConf.ssid(ssid))
        notifies.add(hostapConf.band(band))
        notifies.add(hostapConf.channel(channel))
        notifies.add(hostapConf.password(password))

        hostapConf.cloak if cloak == "1": true else: false

        hostapConf.write()

        if notifies.isEmpty:
          notifies.add success, "configuration successful. please restart the access point to apply the changes"

        var 
          hostap: HostAp = HostAp.new()
          conf = await getHostApConf()
          devs = await getDevices(conf.getIface.get)

        let isActive = hostapdIsActive()
        hostap.active(isActive)

        # resp renderNode(renderHostApPane(hostap, sysInfo, devs), request, request.getUserName, "Wireless", tab, notifies=notifies)
        resp renderNode(renderHostApPane(hostap, isModel3, devs), request, request.getUserName, "Wireless", netTab(), notifies=notifies)