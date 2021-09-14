import jester, strutils
import ../views/[temp, network]
import ".."/[types]
import ".."/libs/[syslib, torlib, session, hostAp, wifiScanner, wirelessManager]

export network
template redirectLoginPage*() =
  redirect "/login"

template respNetworkManager*(wifiList: WifiList, curNet: tuple[ssid, ipAddr: string], notice: Notice = new Notice) =
  resp renderNode(renderWifiConfig(@"interface", wifiList, curNet), request, cfg, tab, notice)

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
        let conf = await getHostApConf()
        resp renderNode(renderHostApPane(conf, sysInfo), request, cfg, tab)
      redirectLoginPage()

    get "/interfaces/join/@interface":
      if await request.isLoggedIn():
        # discard execShellCmd("(nohup ./hostapd_fallback_komplex wlan0 eth0) 2>/dev/null")
        # discard execShellCmd("rm nohup.out")
        # deactivateBridgeRelay()
        if (@"interface" == "wlan0") or (@"interface" == "wlan1"):
          
          var wpa = await newWpa(@"interface".parseIface)
          let
            wifiScanResult = await networkList(wpa)
            currentNetwork = await currentNetwork(wpa.wlan)
          net = wpa
          # net.scanned = true
          # if wifiScanResult.code:
          # resp renderNode(renderWifiConfig(@"interface", wifiScanResult, currentNetwork), request, cfg, tab)
          respNetworkManager(wifiScanResult, currentNetwork)
          # else: resp renderNode(renderInterfaces(), request, cfg, tab, notice=Notice(state: failure, message: wifiScanResult.msg))
        else: redirect crPath & "/interfaces"
      redirectLoginPage()

    post "/wireless":
      if await request.isLoggedIn():
        let cloak = request.formData.getOrDefault("ssidCloak").body
        let conf: HostApConf = HostApConf(
          ssid: request.formData.getOrDefault("ssid").body,
          band: request.formData.getOrDefault("band").body,
          channel: request.formData.getOrDefault("channel").body,
          isHidden: if cloak == "1": true else: false,
          password: request.formData.getOrDefault("password").body
        )
        # if await setHostApConf(conf):
        #   resp renderNode(renderHostApPane(waitFor getWlanInfo()), request, cfg, menu=tab, notice=Notice(state: success, message: "Complete WLAN Setting."))
        # resp renderNode(renderHostApPane(waitFor getWlanInfo()), request, cfg, menu=tab, notice=Notice(state: failure, message: "Failed WLAN Setting."))
        discard await setHostApConf(conf)
        redirect "wireless"
      else:
        redirect "/login"

    post "/interfaces/join/@wlan":
      if await request.isLoggedIn():
        if (@"wlan" == "wlan0") or (@"wlan" == "wlan1"):
          if net.scanned:
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
                redirect crPath & "/interfaces/join/" & @"wlan"
            if (essid.len != 0) or (bssid.len != 0):
              let con = await connect(net, (essid: essid, bssid: bssid, password: password))
              if con.code:
                redirect "/"
              # resp renderNode(renderWirelessPane(waitFor getWlanInfo()), request, cfg, menu=tab, notice=Notice(state: failure, message: con.msg))
              net = new Network
            redirect crPath & "/interfaces/join/" & @"wlan"
          redirect crPath & "/interfaces/join/" & @"wlan"
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

