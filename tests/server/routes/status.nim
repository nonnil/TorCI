import std / options
import jester
import ../ server
import result, resultsutils
import karax / [ vdom ]
import ".." / ".." / ".." / src / notice 
import ".." / ".." / ".." / src / lib / tor
import ".." / ".." / ".." / src / lib / sys
import ".." / ".." / ".." / src / lib / wirelessManager

router status:

  get "/torinfo-empty":
    # empty object
    var
      # torStatus = TorStatus()
      # torBridge = Bridge()
      # torInfo = TorInfo(status: torStatus, bridge: torBridge)
      torInfo = TorInfo.default()
    # torinfo.default()
    
    resp $torInfo.render()

  get "/torinfo":
    var
      ti: TorInfo
      notifies: Notifies

    match await getTorInfo("127.0.0.1", 9050.Port):
      Ok(ret): ti = ret
      Err(msg): notifies.add(failure, msg)
    
    resp $ti.render()

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
  
  get "/iface-empty":
    let
      ioInfo: IoInfo = IoInfo.new()
      ap: ConnectedAp = ConnectedAp.new()

    resp $ioInfo.render(ap)

  get "/systeminfo-empty":
    let sysInfo = SystemInfo()
    resp $sysInfo.render()

  post "/io":
    let val = request.formData.getOrDefault("tor-request").body
    echo "hey"
    resp Http200, val

serve(status, 1984.Port)