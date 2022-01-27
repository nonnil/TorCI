import jester
import ../ views / [temp, sys]
import ".." / [ types, notice ]
import ".." / lib / sys as libsys 
import ".." / lib / session

export sys

proc routingSys*(cfg: Config) =
  router sys:
    let tabForSys = Tabs(
      texts: @["Password", "Erase logs", "Update"],
      links: @["/sys/passwd", "/sys/eraselogs", "/sys/update"]
    )

    get "/sys":
      redirect "/sys/passwd"
      #resp renderNode(renderPasswd(), request, cfg, menu=menu)

    post "/sys":
      let user = await getUser(request)
      if user.isLoggedIn:
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
            resp renderNode(renderLogs(), request, user.uname, "", tabForSys, notifies)

          elif erased == failure:
            notifies.add failure, "Failure erase logs"
            resp renderNode(renderLogs(), request, user.uname, "", tabForSys, notifies)

    get "/sys/passwd":
      let user = await getUser(request)
      if user.isLoggedIn:
        # resp renderNode(renderCard("Change Passwd", renderPasswd()), request, cfg, tabForSys)
        resp renderNode(renderChangePasswd(), request, user.uname, "", tabForSys)
      redirect "/login"
    
    get "/sys/eraselogs":
      let user = await getUser(request)
      if user.isLoggedIn:
        resp renderNode(renderLogs(), request, user.uname, "", tabForSys)
      redirect "/login"