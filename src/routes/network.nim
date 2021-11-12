import jester 
import std / strutils
import ../ views / [temp, network]
import ".." / [types, query, utils]
import ".." / lib / [sys, tor, bridges, torbox, session, hostAp, fallbacks, wifiScanner, wirelessManager]

export network

template redirectLoginPage*() =
  redirect "/login"

template respNetworkManager*(wifiList: WifiList, curNet: tuple[ssid, ipAddr: string]) =
  resp renderNode(renderWifiConfig(iface, withCaptive, wifiList, curNet), request, cfg, user.uname, menu=tab)

template respNetworkManager*(wifiList: WifiList, curNet: tuple[ssid, ipAddr: string], notify: Notify) =
  resp renderNode(renderWifiConfig(iface, withCaptive, wifiList, curNet), request, cfg, user.uname, menu=tab, notify = notify)
  
template respApConf*(n: Notify or Notifies) =
  let
    conf = await getHostApConf()
    devs = await getConnectedDevs(conf.iface)
  resp renderNode(renderHostApPane(conf, sysInfo, devs), request, cfg, user.uname, "Wireless", menu=tab, n)

template respApConf*() =
  let
    conf = await getHostApConf()
    devs = await getConnectedDevs(conf.iface)
  resp renderNode(renderHostApPane(conf, sysInfo, devs), request, cfg, user.uname, "Wireless", menu=tab)
  
template respBridges*(n: Notify | Notifies = Notify()) =
  let bridgesSta = await getBridgeStatuses()
  resp renderNode(renderBridgesPage(bridgesSta), request, cfg, user.uname, "Bridges", menu=tab, n)

template respRefuse*() =
  resp renderNode(renderClose(), request, cfg, user.uname, menu=tab)

proc routingNet*(cfg: Config, sysInfo: SystemInfo) =
  router network:
    const crPath = "/net"

    let tab = Menu(
      text: @["Bridges", "Interfaces", "Wireless"],
      anker: @[crPath & "/bridges", crPath & "/interfaces", crPath & "/wireless"]
    )

    var net: Network = new Network

    get "/bridges":
      let user = await getUser(request)
      if user.isLoggedIn:
        respBridges()

      redirectLoginPage()

    get "/interfaces":
      let user = await getUser(request)
      if user.isLoggedIn:
        respRefuse()
        resp renderNode(renderInterfaces(), request, cfg, user.uname, menu=tab)
      redirectLoginPage()
    
    get "/wireless":
      let user = await getUser(request)
      if user.isLoggedIn:
        respApConf()
      redirectLoginPage()

    get "/interfaces/set/?":
      let user = await getUser(request)
      if user.isLoggedIn:
        respRefuse()
        let
          query = initQuery(request.params)
          iface = query.iface

        var clientWln, clientEth: IfaceKind
        # let query = initQuery(params(request))
        
        if not ifaceExists(iface):
          redirect crPath & "/interfaces"

        case iface
        of wlan0, wlan1:

          case iface
          of wlan0:
            clientWln = wlan1
            clientEth = eth0

          of wlan1:
            clientWln = wlan0
            clientEth = eth0

          else: redirect crPath & "/interfaces"
          
          hostapdFallbackKomplex(clientWln, clientEth)
          editTorrc(iface, clientWln, clientEth)
          restartDhcpServer()

          # net.scanned = true
          # if wifiScanResult.code:
          # resp renderNode(renderWifiConfig(@"interface", wifiScanResult, currentNetwork), request, cfg, tab)
          if query.withCaptive:
            redirect crPath & "/interfaces/join/?iface=" & $iface & "&captive=1"

          redirect crPath & "/interfaces/join/?iface=" & $iface
        else: redirect "interfaces"
      redirectLoginPage()
    
    get "/interfaces/join/?":
      let user = await getUser(request)
      if user.isLoggedIn:
        let
          query = initQuery(request.params)
          iface = query.iface
          withCaptive = query.withCaptive

        case iface
        of wlan0, wlan1:
          var wpa = await newWpa(iface)
          let
            wifiScanResult = await networkList(wpa)
            currentNetwork = await currentNetwork(wpa.wlan)
          net = wpa
          respNetworkManager(wifiScanResult, currentNetwork)
        
        else:
          redirect "interfaces"

      redirectLoginPage()

    post "/wireless":
      let user = await getUser(request)
      if user.isLoggedIn:
        let
          band = if sysInfo.model == model3: "g"
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

        if ret.allgreen:
          respApConf(
            Notify(
              status: success,
              msg: "Configuration successful. Please restart this Access Point to apply the changes"
            )
          )

        elif ret.rets.len > 0:
          var notifies: Notifies
          for v in ret.rets:
            notifies.add Notify(status: v.status, msg: v.msg)
          respApConf(notifies)

        else:
          redirect "wireless"

      redirect "/login"
    
    post "/apctl":
      let user = await getUser(request)
      if user.isLoggedIn:
        let ctl = request.formData.getOrDefault("ctl").body
        
        case ctl
        of "reload":
          await hostapdFallback()

        of "disable":
          await disableAp()

        of "enable":
          await enableWlan()

        else:
          redirect "wireless"
        
        redirect "wireless"

    post "/interfaces/join/@wlan":
      let user = await getUser(request)
      if user.isLoggedIn:
        var clientWln, clientEth: IfaceKind
        let
          iface = parseIface(@"wlan")
          captive = request.formData.getOrDefault("captive").body
          withCaptive = if captive == "1": true else: false

        if not ifaceExists(iface):
          redirect crPath & "/interfaces"

        elif not net.scanned:
          redirect crPath & "/interfaces"

        case iface
        of wlan0, wlan1:

          case iface
          of wlan0:
            clientWln = wlan1
            clientEth = eth0

          of wlan1:
            clientWln = wlan0
            clientEth = eth0

          else: redirect crPath & "/interfaces"

          let
            essid = request.formData.getOrDefault("essid").body
            bssid = request.formData.getOrDefault("bssid").body
            password = request.formData.getOrDefault("password").body
            # sec = request.formData.getOrDefault("security").body
            cloak = request.formData.getOrDefault("cloak").body
            ess = request.formData.getOrDefault("ess").body

          net.isHidden = if cloak == "0": true else: false
          net.isEss = if ess == "0": true else: false

          if not net.isEss:
            if password.len == 0:
              redirect crPath & "/interfaces"

          if (essid.len != 0) or (bssid.len != 0):
            let con = await connect(net, (essid: essid, bssid: bssid, password: password))

            if con.code:
              if withCaptive:
                setCaptive(iface, clientWln, clientEth)
              setInterface(iface, clientWln, clientEth)
              saveIptables()
              redirect crPath & "/interfaces"
            net = new Network

          redirect crPath & "/interfaces"
        else:
          redirect crPath & "/interfaces"
        # newConnect()
      redirectLoginPage
      
    post "/torctl":
      let user = await getUser(request)
      if user.isLoggedIn:
        let restart = request.formData.getOrDefault("restartTor").body
        if restart == "1":
          await restartTor()
          redirect "/net/tor"
        
    post "/bridges":
      let user = await getUser(request)
      if user.isLoggedIn:
        var notifies: Notifies
        let
          input: string = request.formData.getOrDefault("input-obfs4").body

          obfs4 = case request.formData.getOrDefault("obfs4-ctl").body
                  of "activate": 1
                  of "deactivate": -1
                  else: 0

          meekAzure = case request.formData.getOrDefault("meekAzure-ctl").body
                      of "activate": 1
                      of "deactivate": -1
                      else: 0

          snowflake = case request.formData.getOrDefault("snowflake-ctl").body
                      of "activate": 1
                      of "deactivate": -1
                      else: 0

        if input.len > 0:
          let fails = await addObfs4(input.splitLines())
          if fails.len == 0:
            notifies.add Notify(status: success, msg: "Success add obfs4 bridges")

          else:
            for (res, msg) in fails:
              notifies.add Notify(status: failure, msg: msg)
              
        if snowflake == 1:
          let activateSf = await activateSnowflake()
        
        # if request.formData.getOrDefault("bridges-ctl").body == 1:
      
        respBridges(notifies)