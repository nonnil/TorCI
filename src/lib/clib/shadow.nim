import ../../types

proc getShadow*(name: cstring): Spwd {.importc: "getspnam", header: "<shadow.h>".}