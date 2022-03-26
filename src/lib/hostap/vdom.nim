import std / [ options, strformat ]
import karax / [ karaxdsl, vdom ]
import conf
import ../ ../ views / renderutils

# procs for front-end
proc renderChannelSelect*(band: char, rpiModel: string): VNode =
  buildHtml(select(name="channel")):
    option(selected="selected"): text "-- Select a channel --"
    if rpiModel == model3:
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

    elif band == 'g':
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

    elif band == 'a':
      option(value="aa"): text "36 at 40 MHz (default)"
      option(value="ab"): text "36 at 80 MHz"
      option(value="ac"): text "40 at 40 MHz"
      option(value="ad"): text "40 at 80 MHz"
      option(value="ae"): text "44 at 40 MHz"
      option(value="af"): text "44 at 80 MHz"
      option(value="ag"): text "48 at 40 MHz"
      option(value="ah"): text "48 at 80 MHz"

proc render*(hostap: HostApConf, rpiModel: string, width = 58): VNode =
  buildHtml(tdiv(class=fmt"columns width-{$width}")):
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
                input(`type`="text", name="ssid", placeholder=hostap.getSSID.get)
              tdiv(class="card-table"):
                label(class="card-title"): text "Band"
                input(`type`="radio", name="band", value="g"): text "2.5GHz"
                input(`type`="radio", name="band", value="a"): text "5GHz"
              tdiv(class="card-table"):
                label(class="card-title"): text "Channel"
                renderChannelSelect(hostap.getBand.get, rpiModel)
              tdiv(class="card-table"):
                if hostap.isHidden:
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
                  text hostap.getSSID.get
          tr():
            td(): text "Band"
            td():
              strong():
                tdiv():
                  text case hostap.getBand.get
                    of 'g':
                      "2.5GHz"
                    of 'a':
                      "5GHz"
                    else:
                      "Unknown"
          tr():
            td(): text "Channel"
            td():
              strong():
                tdiv():
                  text hostap.getChannel.get
          tr():
            td(): text "SSID Cloak"
            td():
              strong():
                tdiv():
                  text if hostap.isHidden: "Hidden" else: "Visible"
          tr():
            td(): text "Password"
            td():
              strong():
                if hostap.getPassword.get.len != 0:
                  tdiv(class="password_field_container"):
                    tdiv(class="black_circle")
                    icon "eye-off"
                    input(class="btn show_password", `type`="radio", name="password_visibility", value="show")
                    input(class="btn hide_password", `type`="radio", name="password_visibility", value="hide")
                    tdiv(class="shadow")
                    tdiv(class="password_preview_field"):
                      tdiv(class="shown_password"): text hostap.getPassword.get
                else:
                  tdiv():
                    text "No password has been set"

proc render*(status: HostApStatus, width = 38): VNode =
  buildHtml(tdiv(class=fmt"columns width-{$width}")):
    tdiv(class="box"):
      tdiv(class="box-header"):
        text "Actions"
      tdiv(class="card-padding"):
        form(`method`="post", action="/net/apctl", enctype="multipart/form-data"):
          if status.isActive:
            button(`type`="submit", class="btn btn-reload", name="ctl", value="reload"): text "Restart"
            button(`type`="submit", class="btn btn-disable", name="ctl", value="disable"): text "Disable"
          else:
            button(`type`="submit", class="btn btn-enable", name="ctl", value="enable"): text "Enable"