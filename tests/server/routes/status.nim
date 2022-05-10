import std / options
import jester
import ../ server
import results, resultsutils
import karax / [ karaxdsl, vdom ]
import ".." / ".." / ".." / src / notice 
import ".." / ".." / ".." / src / lib / tor
import ".." / ".." / ".." / src / lib / sys
import ".." / ".." / ".." / src / lib / wirelessManager
import ".." / ".." / ".." / src / views / renderutils
import ".." / ".." / ".." / src / routes / tabs

router status:

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
    # empty object
    var
      ioInfo: IoInfo = IoInfo.new()
      connectedAp = ConnectedAp.new()
      notifies = Notifies.new()
    
    match await getIoInfo():
      Ok(iface):
        ioInfo = iface
        if isSome(ioInfo.internet):
          let wlan = ioInfo.internet.get

          match await getConnectedAp(wlan):
            Ok(ap): connectedAp = ap
            Err(msg): notifies.add failure, msg
      Err(msg): notifies.add failure, msg

    resp $ioInfo.render(connectedAp)
  
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