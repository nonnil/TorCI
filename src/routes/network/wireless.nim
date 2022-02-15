import jester
import ".." / [ tabs ]
import ".." / ".." / [ types, notice ]
import ".." / ".." / views / [ temp, network ]
import ".." / ".." / lib / [ sys, session, hostAp ]

template respApConf*(n: Notifies) =
  let
    conf = await getHostApConf()
    devs = await getConnectedDevs(conf.iface)
  resp renderNode(renderHostApPane(conf, sysInfo, devs), request, request.getUserName, "Wireless", notifies=n)

template respApConf*() =
  let
    conf = await getHostApConf()
    devs = await getConnectedDevs(conf.iface)
  resp renderNode(renderHostApPane(conf, sysInfo, devs), request, request.getUserName, "Wireless")

proc routerWireless*(sysInfo: SystemInfo) =
  router wireless:
    get "/wireless/@hash":
      loggedIn:
        respApConf()

    get "/wireless":
      loggedIn:
        respApConf()

    post "/wireless":
      loggedIn:
        let
          band = if sysInfo.model == hostAp.model3: "g"
                 else: request.formData.getOrDefault("band").body
          channel = request.formData.getOrDefault("channel").body

        let conf: OrderedTable[string, string] = {
          "ssid": request.formData.getOrDefault("ssid").body,
          "band": band,
          "channel": if channel.len != 1: "" else: channel,
          "hideSsid": request.formData.getOrDefault("ssidCloak").body,
          "password": request.formData.getOrDefault("password").body
        }.toOrderedTable()

        let ret = await setHostApConf(conf)

        var notifies: Notifies = new()
        if ret.allgreen:
          notifies.add success, "configuration successful. please restart the access point to apply the change"
          respApConf(notifies)

        elif ret.rets.len > 0:
          var notifies: Notifies
          for v in ret.rets:
            notifies.add v.state, v.msg
          respApConf(notifies)

        else:
          redirect "wireless"