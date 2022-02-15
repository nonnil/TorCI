import std / unittest, system
import strformat
import ../ src / lib / clib / c_crypt

suite "Encrypt password":
  test "do crypt":
    const
      shadow = "$6$FRuqFx.gDQotf$xph8gaXXM2D1Y8WMYPfUgLUlQivlc/cAZtB2x.xZbIACrlfqnZtgeVAGcVwvV/embpKisdSKSlVkhrEVR0H3X."
      salt = "FRuqFx.gDQotf"

    check:
      shadow == $crypt("nim", fmt"$6${cstring salt}")