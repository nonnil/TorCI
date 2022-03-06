import std / [ os, options ]
import jester, results
import tabs
import ../ views / [ temp, sys ]
import ".." / [ types, notice ]
import ".." / lib / sys as libsys 
import ".." / lib / session

export sys 

proc routingSys*() =
  var tab = Tab.new
  tab.add("Password", "/sys" / "passwd")
  tab.add("Logs", "/sys" / "logs")
  tab.add("Update", "/sys" / "update")

  router sys:
    get "/sys":
      redirect "/sys/passwd"

    post "/sys":
      loggedIn:
        case request.formData["postType"].body
        of "chgPasswd":
          let code = await changePasswd(request.formData["crPassword"].body, request.formData["newPassword"].body, request.formData["re_newPassword"].body)
          if code.isOk:
            redirect("/login")
          else:
            redirect("/login")
        of "eraseLogs":
          let erase = await eraseLogs()
          var notifies: Notifies = new()

          if erase.isOk:
            notifies.add success, "Complete erase logs"
            resp renderNode(renderLogs(), request, request.getUsername, "", tab, notifies)

          notifies.add failure, "Failure erase logs"
          resp renderNode(renderLogs(), request, request.getUsername, "", tab, notifies)

    get "/sys/passwd":
      loggedIn:
        # resp renderNode(renderCard("Change Passwd", renderPasswd()), request, cfg, tabForSys)
        resp renderNode(renderChangePasswd(), request, request.getUserName, "", tab)
      redirect "/login"
    
    get "/sys/eraselogs":
      loggedIn:
        resp renderNode(renderLogs(), request, request.getUsername, "", tab)