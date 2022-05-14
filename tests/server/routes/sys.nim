import jester
import karax / [ karaxdsl, vdom ]
import ../server
import ".." / ".." / ".." / src / [ renderutils, notice ]
import ".." / ".." / ".." / src / lib / sys as libsys
import ".." / ".." / ".." / src / routes / tabs

template tab(): Tab =
  buildTab:
    "Passwd" = "/passwd"

router sys:
  get "/passwd":
    resp: render "Passwd":
      tab: tab
      container:
        renderPasswdChange()
  
  get "/logs":
    resp: render "Logs":
      tab: tab
      container:
        renderLogs()

serve(sys, 1984.Port)