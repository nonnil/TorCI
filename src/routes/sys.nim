import std / [ os, options, asyncdispatch ]
import results, resultsutils
import jester
import karax / [ karaxdsl, vdom ]
import ./ tabs
import ".." / [ renderutils, notice ]
import ".." / lib / sys as libsys 
import ".." / lib / session

export sys 

template tab(): Tab =
  buildTab:
    "Password" = "/sys" / "passwd"
    "Logs" = "/sys" / "logs"
    "Update" = "/sys" / "update"

proc routingSys*() =
  router sys:
    get "/sys":
      redirect "/sys/passwd"

    post "/sys":
      loggedIn:
        case request.formData["postType"].body
        of "chgPasswd":
          let
            oldPasswd = request.formData["crPassword"].body
            newPasswd = request.formData["newPasswd"].body
            rePasswd = request.formData["re_newPasswd"].body
          match await changePasswd(oldPasswd, newPasswd, rePasswd):
            Ok(): redirect "/login"
            Err(): redirect "/login"

    post "/sys/logs":
      loggedIn:
        let ops = request.formData["ops"].body
        case ops
        of "eraseLogs":
          var nc = Notifies.default()

          match await eraseLogs():
            Ok(): nc.add success, "Complete erase logs"
            Err(): nc.add failure, "Failure erase logs"

          resp: render "Logs":
            notice: nc
            tab: tab
            container:
              renderLogs()

    get "/sys/passwd":
      loggedIn:
        resp: render "Passwd":
          tab: tab
          container:
            renderPasswdChange()
    
    get "/sys/eraselogs":
      loggedIn:
        resp: render "Logs":
          tab: tab
          container:
            renderLogs()