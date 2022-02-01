{.passL: "-lcrypt".}

proc crypt*(key, salt: cstring): cstring {.importc: "crypt", header: "<crypt.h>".}