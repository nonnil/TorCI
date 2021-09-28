import jester
import ../views/[temp, sys]
import ".."/[types]
import ".."/libs/[syslib, session]

export sys

proc routingSys*(cfg: Config) =
  router sys:
    let tabForSys = Menu(
      text: @["Password", "Erase logs", "Update"],
      anker: @["/sys/passwd", "/sys/eraselogs", "/sys/update"]
    )

    get "/sys":
      redirect "/sys/passwd"
      #resp renderNode(renderPasswd(), request, cfg, menu=menu)

    post "/sys":
      if await request.isLoggedIn:
        if request.formData["postType"].body == "chgPasswd":
          let code = await changePasswd(request.formData["crPassword"].body, request.formData["newPassword"].body, request.formData["re_newPassword"].body)
          if code:
            # resp renderNode(renderContainer(renderPasswd()), request, cfg, tabForSys, Notice(state: success, message: "TorBox's password had changed."))
            redirect("/login")
          else:
            # resp renderNode(renderContainer(renderPasswd()), request, cfg, tabForSys, Notice(state: failure, message: "Your password doesn't confirmed."))
            redirect("/login")
        elif request.formData["postType"].body == "eraseLogs":
          let erased = await eraseLogs()
          if erased == success:
            resp renderNode(renderLogs(), request, cfg, tabForSys, Notice(status: success, msg: "Complete erased logs"))
          elif erased == failure:
            resp renderNode(renderLogs(), request, cfg, tabForSys, Notice(status: failure, msg: "Failure erased logs"))

    get "/sys/passwd":
      if await request.isLoggedIn():
        # resp renderNode(renderCard("Change Passwd", renderPasswd()), request, cfg, tabForSys)
        resp renderNode(renderChangePasswd(), request, cfg, tabForSys)
      redirect "/login"
    
    get "/sys/eraselogs":
      if await request.isLoggedIn():
        resp renderNode(renderLogs(), request, cfg, tabForSys)
      redirect "/login"