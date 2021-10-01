import jester, strutils
import ../views/[temp, network]
import ".."/[types, query, utils]
import ".."/libs/[syslib, torLib, torboxLib, session, hostAp, fallbacks, wifiScanner, wirelessManager]

export network

template redirectLoginPage*() =
  redirect "/login"

template respNetworkManager*(wifiList: WifiList, curNet: tuple[ssid, ipAddr: string]) =
  resp renderNode(renderWifiConfig(iface, withCaptive, wifiList, curNet), request, cfg, user.uname, menu=tab)

template respNetworkManager*(wifiList: WifiList, curNet: tuple[ssid, ipAddr: string], notice: Notice) =
  resp renderNode(renderWifiConfig(iface, withCaptive, wifiList, curNet), request, cfg, user.uname, menu=tab, notice = notice)
  
template respApConf*(n: Notice = new Notice) =
  let conf = await getHostApConf()
  if n.msg.len > 0:
    resp renderNode(renderHostApPane(conf, sysInfo), request, cfg, user.uname, menu=tab, notice=n)
  resp renderNode(renderHostApPane(conf, sysInfo), request, cfg, user.uname, menu=tab)
  
template respRefuse*() =
  resp renderNode(renderClose(), request, cfg, user.uname, menu=tab)

proc routingNet*(cfg: Config, sysInfo: SystemInfo) =
  router network:
    const crPath = "/net"

    let tab = Menu(
      text: @["Tor", "Interfaces", "Wireless"],
      anker: @[crPath & "/tor", crPath & "/interfaces", crPath & "/wireless"]
    )

    var net: Network = new Network

    get "/tor":
      let user = await getUser(request)
      if user.isLoggedIn:
        respRefuse()
        resp renderNode(renderTorPane(), request, cfg, user.uname, "Tor", menu=tab)
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
          # else: resp renderNode(renderInterfaces(), request, cfg, tab, notice=Notice(state: failure, message: wifiScanResult.msg))
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
          cloak = request.formData.getOrDefault("ssidCloak").body
          band = request.formData.getOrDefault("band").body

        let conf: HostApConf = HostApConf(
          ssid: request.formData.getOrDefault("ssid").body,
          band: if (sysInfo.model == model3) and (band == "a"): "" else: band,
          channel: request.formData.getOrDefault("channel").body,
          isHidden: if cloak == "1": true else: false,
          password: request.formData.getOrDefault("password").body
        )
        let ret = await setHostApConf(conf)
        if ret:
          respApConf(Notice(status: success, msg: "Configuration successful. Please restart this Access Point to apply the changes"))
        else:
          respApConf(Notice(status: failure, msg: "Invalid config"))
        # hostapdFallback()
        # redirect "wireless"
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
            # resp renderNode(renderWirelessPane(waitFor getWlanInfo()), request, cfg, menu=tab, notice=Notice(state: failure, message: con.msg))
            net = new Network

          redirect crPath & "/interfaces"
        else:
          redirect crPath & "/interfaces"
        # newConnect()
      redirectLoginPage

    get "/bridge":
      redirect "/"