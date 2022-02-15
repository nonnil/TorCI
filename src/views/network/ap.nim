import karax / [karaxdsl, vdom]
import ../ renderutils
import ../ ../ types
import ../ ../ lib / hostAp

proc renderChannelSelect(hd: SystemInfo, band: string): VNode

proc renderHostApControl*(conf: HostApConf): VNode =
  buildHtml(tdiv(class="columns width-38")):
    tdiv(class="box"):
      tdiv(class="box-header"):
        text "Actions"
      tdiv(class="card-padding"):
        form(`method`="post", action="/net/apctl", enctype="multipart/form-data"):
          if conf.isActive:
            button(`type`="submit", class="btn btn-reload", name="ctl", value="reload"): text "Restart"
            button(`type`="submit", class="btn btn-disable", name="ctl", value="disable"): text "Disable"
          else:
            button(`type`="submit", class="btn btn-enable", name="ctl", value="enable"): text "Enable"

proc renderHostApConf*(conf: HostApConf, sysInfo: SystemInfo): VNode =
  buildHtml(tdiv(class="columns width-58")):
    tdiv(class="box"):
      tdiv(class="box-header"):
        text "Config"
        tdiv(class="btn edit-button"):
          icon "sliders"
          input(class="opening-button", `type`="radio", name="popout-button", value="open")
          input(class="closing-button", `type`="radio", name="popout-button", value="close")
          tdiv(class="shadow")
          tdiv(class="editable-box"):
            form(`method`="post", action="/net/wireless", enctype="multipart/form-data"):
              tdiv(class="card-table"):
                label(class="card-title"): text "SSID"
                input(`type`="text", name="ssid", placeholder=conf.ssid)
              tdiv(class="card-table"):
                label(class="card-title"): text "Band"
                input(`type`="radio", name="band", value="g"): text "2.5GHz"
                input(`type`="radio", name="band", value="a"): text "5GHz"
              tdiv(class="card-table"):
                label(class="card-title"): text "channel"
                renderChannelSelect(sysInfo, conf.band)
              tdiv(class="card-table"):
                if conf.isHidden:
                  label(class="card-title"): text "Unhide SSID"
                  input(`type`="checkbox", name="ssidCloak", value="0")
                else:
                  label(class="card-title"): text "Hide SSID"
                  input(`type`="checkbox", name="ssidCloak", value="1")
              tdiv(class="card-table"):
                label(class="card-title"): text "Password"
                input(`type`="password", name="password", placeholder="Please enter 8 to 64 characters") 
              button(`type`="submit", class="btn btn-apply saveBtn", name="saveBtn"):
                text "Save"
      table(class="full-width box-table"):
        tbody():
          tr():
            td(): text "SSID"
            td():
              strong():
                tdiv():
                  text conf.ssid
          tr():
            td(): text "Band"
            td():
              strong():
                tdiv():
                  text case conf.band
                    of "g":
                      "2.5GHz"
                    of "a":
                      "5GHz"
                    else:
                      "Unknown"
          tr():
            td(): text "Channel"
            td():
              strong():
                tdiv():
                  text conf.channel
          tr():
            td(): text "SSID Cloak"
            td():
              strong():
                tdiv():
                  text if conf.isHidden: "Hidden" else: "Visible"
          tr():
            td(): text "Password"
            td():
              strong():
                if conf.password.len != 0:
                  tdiv(class="password_field_container"):
                    tdiv(class="black_circle")
                    icon "eye-off"
                    input(class="btn show_password", `type`="radio", name="password_visibility", value="show")
                    input(class="btn hide_password", `type`="radio", name="password_visibility", value="hide")
                    tdiv(class="shadow")
                    tdiv(class="password_preview_field"):
                      tdiv(class="shown_password"): text conf.password
                else:
                  tdiv():
                    text "No password has been set"

proc renderConnectedDevs*(devs: ConnectedDevs): VNode =
  buildHtml(tdiv(class="columns full-width")):
    tdiv(class="box"):
      tdiv(class="box-header"):
        text "Connected Devices"
      table(class="full-width box-table"):
        tbody():
          tr():
            th(): text "MAC Address"
            th(): text "IP Address"
            th(): text "Signal"
          for v in devs:
            tr():
              td(): text if v.macaddr.len != 0: v.macaddr else: "None"
              td(): text if v.ipAddr.len != 0: v.ipAddr else: "None"
              td(): text if v.signal.len != 0: v.signal else: "None"

proc renderChannelSelect(hd: SystemInfo, band: string): VNode =
  buildHtml(select(name="channel")):
    option(selected="selected"): text "-- Select a channel --"
    if hd.model == model3:
      option(value="ga"): text "1 at 20 MHz"
      option(value="gc"): text "2 at 20 MHz"
      option(value="ge"): text "3 at 20 MHz"
      option(value="gg"): text "4 at 20 MHz"
      option(value="gi"): text "5 at 20 MHz"
      option(value="gk"): text "6 at 20 MHz (default)"
      option(value="gm"): text "7 at 20 MHz"
      option(value="go"): text "8 at 20 MHz"
      option(value="gq"): text "9 at 20 MHz"
      option(value="gs"): text "10 at 20 MHz"
      option(value="gu"): text "11 at 20 MHz"

    elif band == "g":
      option(value="ga"): text "1 at 20 MHz"
      option(value="gb"): text "1 at 40 MHz"
      option(value="gc"): text "2 at 20 MHz"
      option(value="gd"): text "2 at 40 MHz"
      option(value="ge"): text "3 at 20 MHz"
      option(value="gf"): text "3 at 40 MHz"
      option(value="gg"): text "4 at 20 MHz"
      option(value="gh"): text "4 at 40 MHz"
      option(value="gi"): text "5 at 20 MHz"
      option(value="gj"): text "5 at 40 MHz"
      option(value="gk"): text "6 at 20 MHz (default)"
      option(value="gl"): text "6 at 40 MHz"
      option(value="gm"): text "7 at 20 MHz"
      option(value="gn"): text "7 at 40 MHz"
      option(value="go"): text "8 at 20 MHz"
      option(value="gp"): text "8 at 40 MHz"
      option(value="gq"): text "9 at 20 MHz"
      option(value="gr"): text "9 at 40 MHz"
      option(value="gs"): text "10 at 20 MHz"
      option(value="gt"): text "10 at 40 MHz"
      option(value="gu"): text "11 at 20 MHz"
      option(value="gv"): text "11 at 40 MHz"

    elif band == "a":
      option(value="aa"): text "36 at 40 MHz (default)"
      option(value="ab"): text "36 at 80 MHz"
      option(value="ac"): text "40 at 40 MHz"
      option(value="ad"): text "40 at 80 MHz"
      option(value="ae"): text "44 at 40 MHz"
      option(value="af"): text "44 at 80 MHz"
      option(value="ag"): text "48 at 40 MHz"
      option(value="ah"): text "48 at 80 MHz"