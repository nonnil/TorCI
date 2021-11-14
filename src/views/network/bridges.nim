import karax/[karaxdsl, vdom]
import ".." / ".." / [types]

proc renderObfs4Ctl*(): VNode =
  buildHtml(tdiv(class="columns width-50")):
    tdiv(class="box"):
      tdiv(class="box-header"):
        text "Bridges Control"
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

proc renderBridgesCtl*(bridgesSta: BridgeStatuses): VNode =
  buildHtml(tdiv(class="columns width-50")):
    tdiv(class="box"):
      tdiv(class="box-header"):
        text "Bridges Control"
      form(`method`="post", action="/net/bridges", enctype="multipart/form-data"):
        table(class="full-width box-table"):
          tbody():
            tr():
              td(): text "Obfs4"
              td():
                strong():
                  if bridgesSta.obfs4:
                    button(class="btn-general btn-danger", `type`="submit", name="obfs4-ctl", value="deactivate"):
                      text "Deactivate"
                  else:
                    button(class="btn-general btn-safe", `type`="submit", name="obfs4-ctl", value="activate"):
                      text "Activate"

            tr():
              td(): text "Meek-Azure"
              td():
                strong():
                  if bridgesSta.meekAzure:
                    button(class="btn-general btn-danger", `type`="submit", name="meekAzure-ctl", value="deactivate"):
                      text "Deactivate"
                  else:
                    button(class="btn-general btn-safe", `type`="submit", name="meekAzure-ctl", value="activate"):
                      text "Activate"

            tr():
              td(): text "Snowflake"
              td():
                strong():
                  if bridgesSta.snowflake:
                    button(class="btn-general btn-danger", `type`="submit", name="snowflake-ctl", value="deactivate"):
                      text "Deactivate"
                  else:
                    button(class="btn-general btn-safe", `type`="submit", name="snowflake-ctl", value="activate"):
                      text "Activate"
                    
# proc renderObfs4Add*(): VNode =
#   buildHtml(tdiv(class="columns")):
#     tdiv(class="box"):
#       tdiv(class="box-header"):
#         text "Add Obfs4 Bridge"
#       form(`method`="post", action="/net/bridges", enctype="miltipart/form-data"):
#         table(class="full-width box-table"):
#           tbody():
#             tr():
#               td(): text
          
proc renderInputObfs4*(): VNode =
  buildHtml(tdiv(class="columns width-50")):
    tdiv(class="box"):
      tdiv(class="box-header"):
        text "Add Obfs4 Bridges"
      form(`method`="post", action="/net/bridges", enctype="multipart/form-data"):
        textarea(
          class="textarea bridge-input",
          name="input-obfs4",
          placeholder="e.g.\nobfs4 xxx.xxx.xxx.xxx:xxxx cert=abcd.. iat-mode=0\nobfs4 yyy.yyy.yyy.yyy:yyyy cert=abcd.. iat-mode=0",
          required=""
        )
        button(class="btn-apply", `type`="submit", name="bridges-ctl", value="1"): text "Add Bridges"