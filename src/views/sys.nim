import karax/[karaxdsl, vdom]

proc renderSys*(): VNode =
  buildHtml(tdiv):
    tdiv(class="bottons"):
      button(): text "Reboot TorBox"
      button(): text "Shutdown TorBox"

proc renderPasswd*(): VNode =
  buildHtml(tdiv(class="")):
    form(`method`="post", action="/sys", enctype="multipart/form-data", class=""):
      label(class=""):text "Current Password"
      input(`type`="password", `required`="", name="crPassword", class="")
      label(class=""): text "New Password (Admin)"
      input(`type`="password", `required`="", name="newPassword", class="")
      label(class=""):text "Retype new password"
      input(`type`="password", `required`="", name="re_newPassword", class="")
      button(`type`="submit", name="postType", value="chgPasswrd",class=""): text "Change Password"

proc renderLogs*(): VNode =
  buildHtml(tdiv(class="")):
    form(`method`="post", action="/sys", enctype="multipart/form-data", class="form"):
      button(`type`="submit", name="postType", value="eraseLogs", class="eraser"): text "Erase Logs"