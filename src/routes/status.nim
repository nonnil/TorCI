import std / [ options, asyncdispatch ]
import results, resultsutils
import jester, karax / [ karaxdsl, vdom ]
import ".." / [ notice, settings ]
import ../ renderutils
import ".." / lib / [ session, sys, wirelessManager ]
import ../ lib / tor
import tabs
# import sugar

proc routingStatus*() =
  router status:

    before "/io":
      resp "Loading"

    get "/io":
      loggedIn:
        var
          ti = TorInfo.default()
          si = SystemInfo.default()
          ii = IoInfo.new()
          ap = ConnectedAp.new()
          nc = Notifies.default()

        match await getTorInfo(cfg.torAddress, cfg.torPort):
          Ok(ret): ti = ret
          Err(msg): nc.add(failure, msg)
        
        match await getSystemInfo():
          Ok(ret): si = ret
          Err(msg): nc.add(failure, msg)

        match await getIoInfo():
          Ok(ret):
            ii = ret
            if isSome(ii.internet):
              let wlan = ii.internet.get
              match await getConnectedAp(wlan):
                Ok(ret): ap = ret
                Err(msg): nc.add(failure, msg)
          Err(msg): nc.add(failure, msg)

        resp: render "Status":
          notice: nc
          container:
            ti.render()
            ii.render(ap)
            si.render()

    post "/io":
      loggedIn:
        # let req = r.formData.getOrDefault("tor-request").body
        let req = request.formData.getOrDefault("tor-request").body
        case req
        of "new-circuit":
          var
            ti = TorInfo.default()
            ii = IoInfo.new()
            si = SystemInfo.default()
            ap = ConnectedAp.new()
            nc = Notifies.default()

          match await getTorInfo(cfg.torAddress, cfg.torPort):
            Ok(ret): ti = ret
            Err(msg): nc.add(failure, msg)

          match await renewTorExitIp(cfg.torAddress, cfg.torPort):
            Ok(ret):
              ti.status(ret)
              nc.add success, "Exit node has been changed."
            Err(msg):
              nc.add(failure, msg)
              nc.add failure, "Request new exit node failed. Please try again later."

          match await getSystemInfo():
            Ok(ret): si = ret
            Err(msg): nc.add failure, msg

          match await getIoInfo():
            Ok(ret):
              ii = ret 
              if isSome(ii.internet):
                let wlan = ii.internet.get
                match await getConnectedAp(wlan):
                  Ok(ret): ap = ret
                  Err(msg): nc.add failure, msg
            Err(msg): nc.add failure, msg

          resp: render "Status":
            notice: nc
            container:
              ti.render()
              ii.render(ap)
              si.render()

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