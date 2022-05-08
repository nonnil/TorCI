import std / [ options, asyncdispatch ]
import jester, results, resultsutils
import ".." / [ notice, settings ]
import ../ views / [ temp, status ]
import ".." / lib / [ session, sys, wirelessManager ]
import ../ lib / tor
import impl_status
# import sugar

export status, impl_status

proc routingStatus*() =
  router status:

    before "/io":
      resp "Loading"

    get "/io":
      loggedIn:
        let torInfo = await loadTorInfo(cfg.torAddress, cfg.torPort)

        var
          notifies: Notifies = new Notifies
          sysInfo: SystemInfo = new SystemInfo
          iface: IO = new IO
          connectedAp: ConnectedAp = new ConnectedAp
        
        match await getSystemInfo():
          Ok(info):
            sysInfo = info

          Err(msg):
            notifies.add failure, msg

        match await getIO():
          Ok(ret):
            iface = ret

            if isSome(iface.internet):
              let wlan = iface.internet.get

              match await getConnectedAp(wlan):
                Ok(ap):
                  connectedAp = ap
                
                Err(msg):
                  notifies.add failure, msg

          Err(msg):
            notifies.add failure, msg

        resp renderNode(
          buildStatusPane(torInfo, sysInfo, iface, connectedAp),
          request,
          request.getUserName,
          "Status",
          notifies = notifies
        )

    post "/io":
      loggedIn:
        # await doTorRequest(request)
        # let ret = await doTorRequest(request)
        # if ret.isSome:
        #   resp ret.get

        # redirect "/io"
        # let req = r.formData.getOrDefault("tor-request").body
        let req = request.formData.getOrDefault("tor-request").body

        case req
        of "new-circuit":
          var
            notifies = new(Notifies)
            # alret: Result[TorStatus, string]
            # checkRet: Result[TorStatus, string]

          # let ts = await checkTor(cfg.torAddress, cfg.torPort)
          let torInfo = await loadTorInfo(cfg.torAddress, cfg.torPort)
          let renew = await renewTorExitIp()

          if renew:
            notifies.add success, "Exit node has been changed."

          else:
            notifies.add failure, "Request new exit node failed. Please try again later."

          # match ts:
          #   Ok(torStatus):
          #     discard await renewTorExitIp()

          #     match await checkTor(cfg.torAddress, cfg.torPort):
          #       Ok(ts2):
          #         if not torStatus.compareExitIp(ts2):
          #           notifies.add success, "Exit node has been changed."

          #       Err():
          #         notifies.add failure, "Request new exit node failed. Please try again later."

          #   Err(str):
          #     notifies.add failure, str
          # doCheckTor(notifies)

          var
            ifaces: IO = new IO
            sysInfo: SystemInfo = new SystemInfo
            connectedAp: ConnectedAp = new ConnectedAp

          # withSome ifaces.getInternet:
          #   some iface:
          #     let wlan = iface
          #     crNet = await currentNetwork(wlan)
          match await getSystemInfo():
            Ok(info):
              sysInfo = info

            Err(msg):
              notifies.add failure, msg

          match await getIO():
            Ok(iface):
              ifaces = iface

              if isSome(ifaces.internet):
                let wlan = ifaces.internet.get

                match await getConnectedAp(wlan):
                  Ok(ap):
                    connectedAp = ap

                  Err(msg):
                    notifies.add failure, msg
            
            Err(msg):
              notifies.add failure, msg

          # var torInfo = new TorInfo
          # torInfo.bridge = 
          # match await loadBridge():
          #   Ok(bridge):
          #     torInfo.bridge = bridge
          #     # torInfo.status = status
          #   Err():
          #     return

          # torInfo.status = checkRet.get
          # doLoadBridge(torInfo)

          resp renderNode(
            buildStatusPane(torInfo, sysInfo, ifaces, connectedAp),
            request,
            request.getUserName,
            "Status",
            notifies=notifies
          )

        of "restart-tor":
          await restartTor()
          redirect "/io"

        else: 
          redirect "/io"
      # redirect "/io"
        # let notifies = await postIO(request)
        # if notifies.isSome:
        #   respIO(notifies.get)
        # redirect "/io"