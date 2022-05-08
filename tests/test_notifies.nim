import std / [ unittest, terminal ]
import karax / [ vdom ]
import ../ src / notice

suite "Notifies":
  var nt = new Notifies
  nt.add success, "Some notifies!"
  styledEcho(fgGreen, "render: ", fgWhite, $nt.render())
  test "notifies render":
    check:
      nt.render().len >= 0