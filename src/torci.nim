import jester
import views/[temp, login]
import routes/[status, network, sys]
import connexion, types, config
import asyncdispatch 
import libs/[syslib, torlib, wifiScanner, wirelessManager]

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
    if await request.isLoggedIn():
      redirect "/io"
    redirect "/login"
  
  get "/login":
    if not await request.isLoggedIn():
      # resp renderNode(renderPanel(renderLoginPanel()), request, cfg)
      resp renderFlat(renderLogin(), cfg)
    redirect "/"
  
  post "/login":
    if not await request.isLoggedIn():
      let
        username = request.formData.getOrDefault("username").body
        password = request.formData.getOrDefault("password").body
        expireTime = await getExpireTime()
        tLogin = await login(username, password, expireTime)
      if tLogin.res:
        # echo "Set token: ", tLogin.token
        setCookie("token", tLogin.token, expires = expireTime, httpOnly = true)
        redirect "/"
    resp renderFlat(renderLogin(), cfg, notice = Notice(state: failure, message: "Invalid username or password"))
    
  get "/net":
    redirect "/net/interfaces"

  extend status, ""
  extend network, "/net"
  extend sys, ""
  
