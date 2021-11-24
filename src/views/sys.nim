import karax/[karaxdsl, vdom]

proc renderSys*(): VNode =
  buildHtml(tdiv):
    tdiv(class="bottons"):
      button(): text "Reboot TorBox"
      button(): text "Shutdown TorBox"

proc renderChangePasswd*(): VNode =
  buildHtml(tdiv(class="columns")):
    tdiv(class="box"):
      tdiv(class="box-header"):
        text "User password"
      form(`method`="post", action="/sys/passwd", enctype="multipart/form-data"):
        table(class="full-width box-table"):
          tbody():
            tr():
              td(): text "Current password"
              td():
                strong():
                  input(`type`="password", `required`="", name="crPassword")
            tr():
              td(): text "New password"
              td():
                strong():
                  input(`type`="password", `required`="", name="newPassword")
            tr():
              td(): text "New password (Retype)"
              td():
                strong():
                  input(`type`="password", `required`="", name="re_newPassword")
        button(class="btn-apply", `type`="submit", name="postType", value="chgPasswd"): text "Apply"
        
proc renderChangePassControlPort*(): VNode =
  buildHtml(tdiv(class="columns")):
    tdiv(class="box"):
      tdiv(class="box-header"):
        text "Change"

proc renderLogs*(): VNode =
  buildHtml(tdiv(class="")):
    form(`method`="post", action="/sys", enctype="multipart/form-data", class="form"):
      button(`type`="submit", name="postType", value="eraseLogs", class="eraser"): text "Erase Logs"