type
  Spwd* {.importc: "struct spwd", header: "<shadow.h>".} = ptr object
    name* {.importc: "sp_namp".}: cstring
    passwd* {.importc: "sp_pwdp".}: cstring
    sp_lstchg {.importc: "sp_lstchg".}: clong
    min {.importc: "sp_min".}: clong
    max {.importc: "sp_max".}: clong
    warn {.importc: "sp_warn".}: clong
    inact {.importc: "sp_inact".}: clong
    expire {.importc: "sp_expire".}: clong
    flag {.importc: "sp_flag".}: culong

proc getShadow*(name: cstring): Spwd {.importc: "getspnam", header: "<shadow.h>".}