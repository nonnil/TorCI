import jester
import views/[temp, login, renderutils]
import routes/[status, network, sys]
import types, config, query, utils, strutils
import asyncdispatch, logging
import libs/[session, syslib, torLib, bridges, torboxLib, hostAp, fallbacks, wifiScanner, wirelessManager]

const configPath {.strdefine.} = "./torci.conf"
let (cfg, fullCfg) = getConfig(configpath)
let sysInfo = getSystemInfo()

routingStatus(cfg, sysInfo)
routingNet(cfg, sysInfo)
routingSys(cfg)

settings:
  port = Port(cfg.port)
  staticDir = cfg.staticDir
  bindAddr = cfg.address

routes:
  get "/":
    let user = await getUser(request)
    if user.isLoggedIn:
      redirect "/io"
    redirect "/login"
  
  get "/login":
    let user = await getUser(request)
    if not user.isLoggedIn:
      # resp renderNode(renderPanel(renderLoginPanel()), request, cfg)
      resp renderFlat(renderLogin(), cfg, "Login")
    redirect "/"
  
  post "/login":
    let user = await getUser(request)
    if not user.isLoggedIn:
      let
        username = request.formData.getOrDefault("username").body
        password = request.formData.getOrDefault("password").body
        expireTime = await getExpireTime()
        ret = await login(username, password, expireTime)
      if ret.res:
        setCookie("torci", ret.token, expires = expireTime, httpOnly = true)
        redirect "/"

    resp renderFlat(renderLogin(), cfg, notify = Notify(status: failure, msg: "Invalid username or password"))
  
  post "/logout":
    let user = await getUser(request)
    if user.isLoggedIn:
      let signout = request.formData.getOrDefault("signout").body
      if signout == "1":
        if await logout(request):
          redirect "/login"

      redirect "/"
    
  get "/net":
    redirect "/net/bridges"
  
  error Http404:
    resp renderFlat(renderError("404 Not Found"), cfg)
    
  error Exception:
    resp renderFlat(renderError("Something went wrong"), cfg)

  extend status, ""
  extend network, "/net"
  extend sys, ""
  
