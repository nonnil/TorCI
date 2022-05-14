import std / options
import jester
import ../ server
import results, resultsutils
import karax / [ karaxdsl, vdom ]
import ".." / ".." / ".." / src / notice 
import ".." / ".." / ".." / src / lib / tor
import ".." / ".." / ".." / src / lib / sys
import ".." / ".." / ".." / src / lib / wirelessManager
import ".." / ".." / ".." / src / renderutils
import ".." / ".." / ".." / src / routes / tabs

router status:
  get "/status":
    var
      ti = TorInfo.default()
      si = SystemInfo.default()
      ii = IoInfo.new()
      ap = ConnectedAp.new()
      nc = Notifies.default()

    match await getTorInfo("127.0.0.1", 9050.Port):
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

  get "/default/status":
    var
      ti = TorInfo.default()
      si = SystemInfo.default()
      ii = IoInfo.new()
      ap = ConnectedAp.new()
      nc = Notifies.default()

    resp: render "Status":
      notice: nc
      container:
        ti.render()
        ii.render(ap)
        si.render()

  get "/default/tor":
    # empty object
    var
      torInfo = TorInfo.default()
    
    resp $torInfo.render()

  get "/tor":
    var
      ti: TorInfo = TorInfo.default()
      nc: Notifies = Notifies.default()

    match await getTorInfo("127.0.0.1", 9050.Port):
      Ok(ret): ti = ret
      Err(msg): nc.add(failure, msg)
    
    resp: render "Tor":
      notice: nc
      container:
        ti.render()

  get "/iface":
    var
      ioInfo: IoInfo = IoInfo.new()
      connectedAp = ConnectedAp.new()
      nc = Notifies.default()
    
    match await getIoInfo():
      Ok(iface):
        ioInfo = iface
        if isSome(ioInfo.internet):
          let wlan = ioInfo.internet.get

          match await getConnectedAp(wlan):
            Ok(ap): connectedAp = ap
            Err(msg): nc.add failure, msg
      Err(msg): nc.add failure, msg

    resp: render "I/O":
      notice: nc
      container:
        ioInfo.render(connectedAp)

  get "/default/iface":
    let
      ioInfo: IoInfo = IoInfo.new()
      ap: ConnectedAp = ConnectedAp.new()

    resp $ioInfo.render(ap)

  get "/default/sys":
    let sysInfo = SystemInfo.default()
    resp $sysInfo.render()

  get "/sys":
    var
      sysInfo = SystemInfo.default()
      nc = Notifies.default()

    match await getSystemInfo():
      Ok(ret): sysInfo = ret
      Err(msg): nc.add(failure, msg)

    resp: render "System":
      notice: nc
      container:
        sysInfo.render()

  post "/io":
    let val = request.formData.getOrDefault("tor-request").body
    echo "hey"
    resp Http200, val

serve(status, 1984.Port)