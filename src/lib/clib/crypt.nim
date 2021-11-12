{.passL: "-lcrypt".}

proc ccrypt*(key, salt: cstring): cstring {.importc: "crypt", header: "<crypt.h>".}