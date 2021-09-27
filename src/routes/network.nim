import jester, strutils, strformat
import ../views/[temp, network]
import ".."/[types, query, utils]
import ".."/libs/[syslib, torLib, torboxLib, session, hostAp, fallbacks, wifiScanner, wirelessManager]

export network

template redirectLoginPage*() =
  redirect "/login"

template respNetworkManager*(wifiList: WifiList, curNet: tuple[ssid, ipAddr: string], notice: Notice = new Notice) =
  resp renderNode(renderWifiConfig(iface, withCaptive, wifiList, curNet), request, cfg, tab, notice)
  
template respWifiConf*(notice: Notice = new Notice) =
  let conf = await getHostApConf()
  if notice.msg.len != 0:
    resp renderNode(renderHostApPane(conf, sysInfo), request, cfg, tab, notice)
  resp renderNode(renderHostApPane(conf, sysInfo), request, cfg, tab)

proc routingNet*(cfg: Config, sysInfo: SystemInfo) =
  router network:
    const crPath = "/net"

    let tab = Menu(
      text: @["Tor", "Interfaces", "Wireless"],
      anker: @[crPath & "/tor", crPath & "/interfaces", crPath & "/wireless"]
    )

    var net: Network = new Network

    get "/tor":
      if await request.isLoggedIn():
        resp renderNode(renderTorPane(), request, cfg, tab)
      redirectLoginPage()

    get "/interfaces":
      if await request.isLoggedIn():
        resp renderNode(renderInterfaces(), request, cfg, tab)
      redirectLoginPage()
    
    get "/wireless":
      if await request.isLoggedIn():
        # let conf = await getHostApConf()
        # resp renderNode(renderHostApPane(conf, sysInfo), request, cfg, tab)
        respWifiConf()
      redirectLoginPage()

    get "/interfaces/set/?":
      if await request.isLoggedIn():
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
        else: redirect crPath & "/interfaces"
      redirectLoginPage()
    
    get "/interfaces/join/?":
      if await request.isLoggedIn():
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
          redirect crPath & "/interfaces"

      redirectLoginPage()

    post "/wireless":
      if await request.isLoggedIn():
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
        # if await setHostApConf(conf):
        #   resp renderNode(renderHostApPane(waitFor getWlanInfo()), request, cfg, menu=tab, notice=Notice(state: success, message: "Complete WLAN Setting."))
        # resp renderNode(renderHostApPane(waitFor getWlanInfo()), request, cfg, menu=tab, notice=Notice(state: failure, message: "Failed WLAN Setting."))
        let ret = await setHostApConf(conf)
        if ret:
          respWifiConf(Notice(status: success, msg: "Configuration successful. Please restart this Access Point to apply the changes"))
        else:
          respWifiConf(Notice(status: failure, msg: "Invalid config"))
        # hostapdFallback()
        # redirect "wireless"
      redirect "/login"
    
    post "/apctl":
      if await request.isLoggedIn():
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
      if await request.isLoggedIn():
        var clientWln, clientEth: IfaceKind
        let
          iface = parseIface(@"wlan")
          captive = request.formData.getOrDefault("captive").body
          isCaptive = if captive == "1": true else: false

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
              if isCaptive:
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

    # proc createCard(): Future[Card] {.async.} =
    #   let
    #     wlan = await getWlanInfo()
    #     card = Card(
    #       kind: editable,
    #       path: crPath & "/wlan",
    #       status: @[normal, normal, normal, normal, normal],
    #       str: @["SSID", "Country code", "Channel", "Input Device", "Output Device"],
    #       message: @[wlan["ssid"], wlan["interface"], wlan.getOrDefault("channel"),  wlan.getOrDefault("input"), wlan.getOrDefault("output") ],
    #       editType: @[text, box, text, text, text, text]
    #     )
    #   result = card

    # get "/wlan":
    #   if await request.loggedIn():
    #     let wlan = await getWlanInfo()
    #     let card = Card(
    #       kind: editable,
    #       path: crPath & "/wlan",
    #       status: @[normal, normal, normal, normal, normal],
    #       str: @["SSID", "Country code", "Channel", "Input Device", "Output Device"],
    #       message: @[wlan["ssid"], wlan["interface"], wlan.getOrDefault("channel"),  wlan.getOrDefault("input"), wlan.getOrDefault("output") ]
    #     )
    #     # resp renderNode(renderCard("WLAN Information", card), request, cfg, tab)
    #     resp renderNode(renderWlanCOnfig(wlan), request, cfg, tab)
    #   redirect "/login"
    # post "/wlan":
    #   if await request.loggedIn():
    #     echo $request.formData
    #     let
    #       ssid = request.formData.getOrDefault("SSID").body
    #       countryCode = request.formData.getOrDefault("Country code").body
    #       channel = request.formData.getOrDefault("band").body
    #       inputDevice = request.formData.getOrDefault("Input Device").body
    #       outputDevice = request.formData.getOrDefault("Output Device").body
    #     if await changeSsid(ssid):
    #       # resp renderNode(renderCard("WLAN Information", await createCard()), request, cfg, tab, Notice(state: success, message: "Success config WLAN"))
    #       let
    #         wlan = await getWlanInfo()
    #         card = Card(
    #           kind: editable,
    #           path: crPath & "wlan",
    #           status: @[normal, normal, normal, normal, normal],
    #           str: @["SSID", "Country Code", "Channel", "Input Device", "Output Device"], 
    #           message: @[wlan["ssid"], wlan["interface"], wlan.getOrDefault("channel"), wlan.getOrDefault("input"), wlan.getOrDefault("output") ]
    #         )
    #       resp renderNode(renderWlanConfig(wlan), request, cfg, tab, Notice(state: success, message: "Saved config of WLAN"))
    #     resp renderNode(renderWlanConfig(waitFor getWlanInfo()), request, cfg, tab, Notice(state: failure, message: "Failed config"))
    #   redirect "/net/wlan"

