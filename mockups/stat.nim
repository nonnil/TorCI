import std / [ options, importutils ] 
import jester
import results, resultsutils, jsony
import karax / [ karaxdsl, vdom, vstyles ]
import ../ tests / server / server
import ".." / src / notice 
import ".." / src / lib / tor {.all.}
import ".." / src / lib / sys
import ".." / src / lib / wirelessManager
import ".." / src / renderutils
import ".." / src / routes / tabs
import std / times
import std / json

router stat:
  get "/api/checktor":
    var check = TorStatus.new()
    match await checkTor("127.0.0.1", 9050.Port):
      Ok(ret): check = ret
      Err(): discard
    resp check.toJson().fromJson()

  get "/api/bridgesinfo":
    var br: Bridge
    match await getBridge():
      Ok(ret): br = ret
      Err(): discard
    resp br.toJson().fromJson()

  get "/api/sysinfo":
    var si = SystemInfo.default()
    match await getSystemInfo():
      Ok(ret): si = ret
      Err(): discard
    resp si.toJson().fromJson()

  get "/api/ioinfo":
    var
      ii = IoInfo.new()
      ap = ConnectedAp.new()
    match await getIoInfo():
      Ok(ret): ii = ret
      Err(): discard
    if ii.internet.isSome:
      let iface = ii.internet.get
      match await getConnectedAp(iface):
        Ok(ret): ap = ret
        Err(): discard
    echo ap.toJson()
    var j = ii.toJson().fromJson()
    let j2 = ap.toJson().fromJson()
    # j.add(ap.toJson().fromJson())
    j.add("ap", j2)
    echo j
    resp j
  
  # get "/api/ap":
  #   var ap = ConnectedAp.new()
  #   match await getConnectedAp():
  #     Ok(ret): ap = ret
  #     Err(): discard
  #   resp ap.toJson().fromJson()

  get "/io/js2":
    resp: render "JS2":
      container:
        TorInfo.render2()

  get "/io/js":
    resp: render "JS":
      container:
        buildhtml(tdiv(id="ROOT"))
        buildHtml(script(`type`="text/javascript", src="/js/status.js"))

  get "/static/io":
    privateAccess(TorInfo)
    privateAccess(TorStatus)
    privateAccess(Bridge)
    privateAccess(IoInfo)
    privateAccess(SystemInfo)
    privateAccess(CpuInfo)
    privateAccess(ConnectedAp)
    var
      ti = TorInfo(
        status: TorStatus(isTor: true),
        bridge: Bridge(
          useBridges: true,
          kind: obfs4
        )
      )

      si = SystemInfo(
        cpu: CpuInfo(
          model: "Raspberry Pi 4 Model B Rev 1.2",
          architecture: "ARMv7 Processor rev 3 (v7l)"
        ),
        kernelVersion: "5.10.17-v7l+",
        torboxVer: "0.5.0"
      )

      ii = IoInfo(
        internet: some(wlan0),
        hostap: some(wlan1)
      )

      ap = ConnectedAp(
        ssid: "Mirai-bot",
        ipaddr: "192.168.19.84"
      )

    resp: render "Status":
      container:
        ti.render()
        ii.render(ap)
        si.render()
  
  before "/cube":
    let cube = buildHtml(tdiv(class="loading cube")):
      tdiv()
      tdiv()
      tdiv()
      tdiv()
      tdiv()
      tdiv()

    resp: render "Cube":
      container:
        cube

  patch "/cube":
    await sleepAsync(5000)
    let greet = buildHtml(tdiv()):
      text "I'm wake up"
    resp renderFlat(greet, "Cube")

  get "/test":
    resp """<!DOCTYPE html>

<html>
  <head>
    <title>Multiple Karax apps</title>
  </head>

  <body id="body">

    <style>
      #ROOT1 { float: left; }
      #ROOT2 { float: right; }
      .clearfix {clear: both;}
    </style>

    <h1>Use multiple karax apps.</h1>

    <div id="ROOT1"></div>
    <script type="text/javascript" src="/js/app1.js"></script>

    <div id="ROOT2"></div>
    <script type="text/javascript" src="/js/app2.js"></script>

    <hr class="clearfix">
    <h2>Some example html</h2>
    <table>
      <tr>
        <th>Company</th>
        <th>Contact</th>
        <th>Country</th>
      </tr>
      <tr>
        <td>Alfreds Futterkiste</td>
        <td>Maria Anders</td>
        <td>Germany</td>
      </tr>
      <tr>
        <td>Centro comercial Moctezuma</td>
        <td>Francisco Chang</td>
        <td>Mexico</td>
      </tr>
    </table>

  </body>
</html>"""

serve(stat, 1984.Port)