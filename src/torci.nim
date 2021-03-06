import std / [ strutils, options, asyncdispatch ]
import jester, karax / [ karaxdsl, vdom]
import results, resultsutils

import views / [ login ]
import routes / [ status, network, sys, tabs ]
import ./ renderutils, types, config, query, utils, notice
import settings as torciSettings
import lib / [ tor, session, torbox, hostap, fallbacks, wifiScanner, wirelessManager ]
import lib / sys as libsys

{.passL: "-flto", passC: "-flto", optimization: size.}
# {.passC: "/usr/include/x86_64-linux-musl".}
# {.passL: "-I/usr/include/x86_64-linux-musl".}

routingStatus()
# routerWireless()
routingNet()
routingSys()

settings:
  port = cfg.port
  staticDir = cfg.staticDir
  bindAddr = cfg.address

routes:
  get "/":
    loggedIn:
      redirect "/io"
  
  get "/login":
    notLoggedIn:
      resp renderFlat(renderLogin(), "Login")
  
  post "/login":
    template respLogin() =
      resp renderFlat(renderLogin(), "Login", notifies = nc)

    notLoggedIn:
      let
        username = request.formData.getOrDefault("username").body
        password = request.formData.getOrDefault("password").body
      var nc = Notifies.default()

      match await login(username, password):
        Ok(res):
          setCookie("torci", res.token, expires = res.expire, httpOnly = true)
          redirect "/"
        Err(msg):
          nc.add(failure, msg)
          respLogin()

      # respLogin()
  
  post "/logout":
    loggedIn:
      let signout = request.formData.getOrDefault("signout").body
      if signout == "1":
        if await logout(request):
          redirect "/login"

      redirect "/"
    
  get "/net":
    redirect "/net/bridges"
  
  error Http404:
    resp renderFlat(renderError("404 Not Found"), "404 Not Found")
    
  error Exception:
    resp renderFlat(renderError("Something went wrong"), "Error")

  extend status, ""
  extend network, "/net"
  # extend wireless, "/net"
  extend sys, ""