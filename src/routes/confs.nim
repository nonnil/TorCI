import jester
import ../views/[temp, confs]
import ".."/[types, connexion]
import asyncdispatch

export confs

proc routingConfs*(cfg: Config) =
  router confs:
    let tabForConfs = Menu(
      text: @["WLAN"],
      anker: @["/confs/wlan"]
    )
    #const listname = (@["passwd", "Bridges", "Restart"], @["/confs/passwd", "/confs/bridge", "/confs/restor"])
      #resp renderNode(renderContainer(renderBridge()), request, cfg)
      # v2 response func
      # resp renderNode(renderMenuList(@["Change Admin password", "Bridge setting"], @["/confs/passwd", "/confs/bridge"]), request, cfg)
      # v3 response func
      # resp renderNode(renderConfs(), request, cfg)
    get "/bridge":
      await listAllBridges()
      resp renderNode(renderContainer(renderBridge()), request, cfg, menu=tabForConfs)
    
    get "/resstart_tor":
      let _ = await restartTor()
      resp renderNode(renderContainer(renderBridge()), request, cfg, menu=tabForConfs)

    # get "/wlan":
    #   let wlanInfo = await getWlanInfo()
    #   echo "Its a WLAN infomation on /confs/wlan: " & $wlaninfo
    #   let card = Card(
    #     status: @[normal, normal, normal, normal, normal],
    #     str: @["SSID", "Country code", "Channel", "Input Device", "Output Device"],
    #     message: @[wlaninfo["ssid"], wlaninfo["interface"], wlaninfo.getOrDefault("channel"),  wlaninfo.getOrDefault("input"), wlaninfo.getOrDefault("output") ])
    #   resp renderNode(renderCard("WLAN Information", card), request, cfg, menu=tabForConfs)
    get "/wlan":
      if await request.loggedIn():
        let wlan = await getWlanInfo()
        resp renderNode(renderWlanPane(wlan), request, cfg, menu=tabForConfs)
      redirect "/login"
    post "/wlan":
      if await request.loggedIn():
        let wlan: Wlan = Wlan(
          ssid: request.formData.getOrDefault("ssid").body,
          band: request.formData.getOrDefault("band").body,
          ssidCloak: request.formData.getOrDefault("ssidCloak").body
        )
        if await setWlanConfig(wlan):
          resp renderNode(renderWlanPane(waitFor getWlanInfo()), request, cfg, menu=tabForConfs, notice=Notice(state: success, message: "Complete WLAN Setting."))
        resp renderNode(renderWlanPane(waitFor getWlanInfo()), request, cfg, menu=tabForConfs, notice=Notice(state: failure, message: "Failed WLAN Setting."))
      else:
        redirect "/login"
