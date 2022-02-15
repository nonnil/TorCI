import std / [ os, options ]
import jester
import tabs
import ../ views / [ temp, sys ]
import ".." / [ types, notice ]
import ".." / lib / sys as libsys 
import ".." / lib / session

export sys 

var sys_tab* = Tab.new
sys_tab.add("Password", "/sys" / "passwd")
sys_tab.add("Logs", "/sys" / "logs")
sys_tab.add("Update", "/sys" / "update")

proc routingSys*() =
  router sys:

    get "/sys":
      redirect "/sys/passwd"

    post "/sys":
      loggedIn:
        case request.formData["postType"].body
        of "chgPasswd":
          let code = await changePasswd(request.formData["crPassword"].body, request.formData["newPassword"].body, request.formData["re_newPassword"].body)
          if code:
            redirect("/login")
          else:
            redirect("/login")
        of "eraseLogs":
          let erased = await eraseLogs()
          var notifies: Notifies = new()
          if erased == success:
            notifies.add success, "Complete erase logs"
            resp renderNode(renderLogs(), request, request.getUsername, "", sys_tab, notifies)

          elif erased == failure:
            notifies.add failure, "Failure erase logs"
            resp renderNode(renderLogs(), request, request.getUsername, "", sys_tab, notifies)

    get "/sys/passwd":
      loggedIn:
        # resp renderNode(renderCard("Change Passwd", renderPasswd()), request, cfg, tabForSys)
        resp renderNode(renderChangePasswd(), request, request.getUserName, "", sys_tab)
      redirect "/login"
    
    get "/sys/eraselogs":
      loggedIn:
        resp renderNode(renderLogs(), request, request.getUsername, "", sys_tab)