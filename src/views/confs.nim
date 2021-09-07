import karax/[karaxdsl, vdom, vstyles]
import temp
import ../types
import tables

proc renderConfs*():VNode =
  buildHtml(tdiv):
    a(class="", href="/confs/passwd"): text "Change Admin Password"

proc renderBridge*(): VNode =
  buildHtml(tdiv(class="")):
    form(`method`="post", action="/confs", enctype="multipart/form-data", class=""):
      button(`type`="submit", name="toggleBridge", class=""):
        text "Tor Bridge on | off"

proc renderWlanConfig*(): VNode =
  buildHtml(tdiv(class="")):
    form(`method`="post", action="/confs", enctype="multipart/form-data", class=""):
      button(`type`="submit", name="postType", value="hideWlan", class=""): text "Hide TorBox's WLAN"
    form(`method`="post", action="/confs", enctype="multipart/form-data", class=""):
      button(`type`="submit", name="postType", value="disableWlan", class=""): text "Disable TorBox's WLAN"

proc renderWlanInfo*(): VNode =
  buildHtml(tdiv(class="infomation-table")):
    text "test"

proc renderWlanPowerButton*(): VNode =
  buildHtml(tdiv(class="card")):
    tdiv(class="card-header"):
      text "WLAN Power"
    tdiv(class="card-body"):
      form(`method`="post", action="/confs/wlan", enctype="multipart/form-data"):
        button(`type`="submit", class="btn-reload", name="status", value="reload"): text "Restart"
        button(`type`="submit", class="btn-enable", name="status", value="enable"): text "Enable"
        button(`type`="submit", class="btn-disable", name="status", value="disable"): text "Disable"

proc renderWlanConfig*(wlan: Wlan): VNode =
  buildHtml(tdiv(class="card")):
    tdiv(class="card-header"):
      text "Wi-Fi Configuration"
      tdiv(class="edit-button"):
        label(): text "Edit"
        input(class="opening-button", `type`="radio", name="popout-button", value="open")
        input(class="closing-button", `type`="radio", name="popout-button", value="close")
        tdiv(class="shadow")
        tdiv(class="editable-box"):
          form(`method`="post", action="/confs/wlan", enctype="multipart/form-data"):
            tdiv(class="card-table"):
              label(class="card-title"): text "SSID"
              input(`type`="text", name="ssid", placeholder=wlan.ssid)
            tdiv(class="card-table"):
              label(class="card-title"): text "Band"
              select(name="band"):
                option(value="g"): text "2.5GHz"
                option(value="a"): text "5GHz"
            tdiv(class="card-table"):
              label(class="card-title"): text "SSID Cloak"
              select(name="ssidCloak"):
                option(value="hide"): text "Hide"
                option(value="unhide"): text "Unhide"
            button(`type`="submit", class="saveBtn", name="saveBtn"): text "Save change"
    tdiv(class="card-body"):
      tdiv(class="card-table"):
        tdiv(class="card-title"): text "SSID"
        tdiv(class="card-text", style=style {color: "#444"}):
          text wlan.ssid
      tdiv(class="card-table"):
        tdiv(class="card-title"): text "Band"
        tdiv(class="card-text", style=style {color: "#444"}):
          text if wlan.band == "a": "2.5GHz"
               else: "5GHz"
      tdiv(class="card-table"):
        tdiv(class="card-title"): text "SSID Public"
        tdiv(class="card-text", style=style {color: "#444"}):
          text if wlan.ssidCloak == $0: "Visible" else: "Hidden"
 
proc renderWlanPane*(wlan: Wlan): VNode =
  buildHtml(tdiv(class="cards")):
    renderWlanConfig(wlan)
    renderWlanPowerButton()