{.passL: "-lcrypt".}

proc crypt*(key, salt: cstring): cstring {.importc: "crypt", header: "<crypt.h>".}

proc crypt*(key, salt: string): string =
  let crypt = crypt(cstring(key), cstring(salt))
  $crypt