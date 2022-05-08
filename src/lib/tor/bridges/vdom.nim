import karax / [ karaxdsl, vdom ]
import bridge

proc renderObfs4Ctl*(): VNode =
  buildHtml(tdiv(class="columns width-50")):
    tdiv(class="box"):
      tdiv(class="box-header"):
        text "Actions"
      form(`method`="post", action="/net/bridges", enctype="multipart/form-data"):
        table(class="full-width box-table"):
          tbody():
            tr():
              td(): text "All configured Obfs4"
              td():
                strong():
                  button(`type`="submit", name="obfs4", value="all"):
                    text "Activate"
            tr():
              td(): text "Online Obfs4 only"
              td():
                strong():
                  button(`type`="submit", name="obfs4", value="online"):
                    text "Activate"
            tr():
              td(): text "Auto Obfs4 "
              td():
                strong():
                  button(`type`="submit", name="auto-add-obfs4", value="1"):
                    text "Add"

method render*(bridge: Bridge): VNode {.base.} =
  buildHtml(tdiv(class="columns width-50")):
    tdiv(class="box"):
      tdiv(class="box-header"):
        text "Actions"
      form(`method`="post", action="/net/bridges", enctype="multipart/form-data"):
        table(class="full-width box-table"):
          tbody():
            tr():
              td(): text "Obfs4"
              td():
                strong():
                  if bridge.kind == obfs4:
                    button(class="btn-general btn-danger", `type`="submit", name="bridge-action", value="obfs4-deactivate"):
                      text "Deactivate"
                  else:
                    button(class="btn-general btn-safe", `type`="submit", name="bridge-action", value="obfs4-activate-all"):
                      text "Activate"

            tr():
              td(): text "Meek-Azure"
              td():
                strong():
                  if bridge.kind == meekAzure:
                    button(class="btn-general btn-danger", `type`="submit", name="bridge-action", value="meekazure-deactivate"):
                      text "Deactivate"
                  else:
                    button(class="btn-general btn-safe", `type`="submit", name="bridge-action", value="meekazure-activate"):
                      text "Activate"

            tr():
              td(): text "Snowflake"
              td():
                strong():
                  if bridge.kind == snowflake:
                    button(class="btn-general btn-danger", `type`="submit", name="bridge-action", value="snowflake-deactivate"):
                      text "Deactivate"
                  else:
                    button(class="btn-general btn-safe", `type`="submit", name="bridge-action", value="snowflake-activate"):
                      text "Activate"
                    
proc renderInputObfs4*(): VNode =
  buildHtml(tdiv(class="columns width-50")):
    tdiv(class="box"):
      tdiv(class="box-header"):
        text "Add a bridge"
      form(`method`="post", action="/net/bridges", enctype="multipart/form-data"):
        textarea(
          class="textarea bridge-input",
          name="input-bridges",
          placeholder="e.g.\n" &
          "obfs4 xxx.xxx.xxx.xxx:xxxx FINGERPRINT cert=abcd.. iat-mode=0\n" &
          "meek_lite 192.0.2.2:2 FINGERPRINT url=https://meek.torbox.ch/ front=ajax.torbox.ch\n" &
          "snowflake 192.0.2.3:1 FINGERPRINT",
          required=""
        )
        button(class="btn-apply", `type`="submit", name="bridges-ctl", value="1"):
          text "Enter"