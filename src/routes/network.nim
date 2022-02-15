import std / [ strutils, os ]
import jester 
import tabs
import ../ views / [ temp, network ]
import ".." / [ types, query, utils, notice ]
import ".." / lib / [ sys, tor, bridges, torbox, session, hostAp, fallbacks, wifiScanner, wirelessManager ]
import network / wireless

export network, wireless

var net_tab* = Tab.new
net_tab.add("Bridges", "/net" / "bridges")
net_tab.add("Interfaces", "/net" / "interfaces")
net_tab.add("Wireless", "/net" / "wireless")

template respNetworkManager*(wifiList: WifiList, curNet: tuple[ssid, ipAddr: string]) =
  resp renderNode(renderWifiConfig(iface, withCaptive, wifiList, curNet), request, request.getUserName, "Network management", net_tab)

template respNetworkManager*(wifiList: WifiList, curNet: tuple[ssid, ipAddr: string], n: Notifies) =
  resp renderNode(renderWifiConfig(iface, withCaptive, wifiList, curNet), request, request.getUserName, tab, n)

template respBridges*() =
  let bridgesSta = await getBridgeStatuses()
  resp renderNode(renderBridgesPage(bridgesSta), request, request.getUserName, "Bridges", net_tab)

template respBridges*(n: Notifies) =
  let bridgesSta = await getBridgeStatuses()
  resp renderNode(renderBridgesPage(bridgesSta), request, request.getUserName, "Bridges", net_tab, n)

template respMaintenance*() =
  resp renderNode(renderClosed(), request, request.getUserName, "Under maintenance", net_tab)

proc routingNet*(sysInfo: SystemInfo) =
  routerWireless(sysInfo)

  router network:

    extend wireless, ""

    var net: Network = new Network

    get "/bridges":
      loggedIn:
        respBridges()

    get "/interfaces":
      loggedIn:
        respMaintenance()
        # resp renderNode(renderInterfaces(), request, request.getUserName, "Interfaces", tab)

    get "/interfaces/set/?":
      loggedIn:
        respMaintenance()
        let
          query = initQuery(request.params)
          iface = query.iface

        var clientWln, clientEth: IfaceKind
        # let query = initQuery(params(request))
        
        if not ifaceExists(iface):
          redirect "interfaces"

        case iface
        of wlan0, wlan1:

          case iface
          of wlan0:
            clientWln = wlan1
            clientEth = eth0

          of wlan1:
            clientWln = wlan0
            clientEth = eth0

          else: redirect "interfaces"
          
          hostapdFallbackKomplex(clientWln, clientEth)
          editTorrc(iface, clientWln, clientEth)
          restartDhcpServer()

          # net.scanned = true
          # if wifiScanResult.code:
          # resp renderNode(renderWifiConfig(@"interface", wifiScanResult, currentNetwork), request, cfg, tab)
          if query.withCaptive:
            redirect "interfaces/join/?iface=" & $iface & "&captive=1"

          redirect "interfaces/join/?iface=" & $iface
        else: redirect "interfaces"

    get "/interfaces/join/?":
      # let user = await getUser(request)
      # if user.isLoggedIn:
      loggedIn:
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

    post "/apctl":
      loggedIn:
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
      loggedIn:
        var clientWln, clientEth: IfaceKind
        let
          iface = parseIface(@"wlan")
          captive = request.formData.getOrDefault("captive").body
          withCaptive = if captive == "1": true else: false

        if not ifaceExists(iface):
          redirect "interfaces"

        elif not net.scanned:
          redirect "interfaces"

        case iface
        of wlan0, wlan1:

          case iface
          of wlan0:
            clientWln = wlan1
            clientEth = eth0

          of wlan1:
            clientWln = wlan0
            clientEth = eth0

          else: redirect "interfaces"

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
              redirect "interfaces"

          if (essid.len != 0) or (bssid.len != 0):
            let con = await connect(net, (essid: essid, bssid: bssid, password: password))

            if con.code:
              if withCaptive:
                setCaptive(iface, clientWln, clientEth)
              setInterface(iface, clientWln, clientEth)
              saveIptables()
              redirect "interfaces"
            net = new Network

          redirect "interfaces"
        else:
          redirect "interfaces"
        # newConnect()
      
    post "/bridges":
      loggedIn:
        var notifies: Notifies
        let
          input: string = request.formData.getOrDefault("input-bridges").body
          action = request.formData.getOrDefault("bridge-action").body

        if input.len > 0:
          let (failure, success) = await addBridges(input)
          if failure == 0 and
          success > 0:
            notifies.add State.success, "Bridge has been added"

          elif failure > 0 and
          success > 0:
            notifies.add State.warn, "Some bridges failed to add"

          else:
            notifies.add State.failure, "Failed to bridge add"
          
        if action.len > 0:
          case action

          of "obfs4-activate-all":
            await activateObfs4(ActivateObfs4Kind.all)

          of "obfs4-activate-online":
            await activateObfs4(ActivateObfs4Kind.online)

          of "obfs4-deactivate":
            await deactivateObfs4()

          of "meekazure-activate":
            await activateMeekazure()

          of "meekazure-deactivate":
            await deactivateMeekazure()

          of "snowflake-activate":
            await activateSnowflake()

          of "snowflake-deactivate":
            await deactivateSnowflake()

        if notifies.len > 0:
          respBridges(notifies)
        else:
          redirect "bridges"