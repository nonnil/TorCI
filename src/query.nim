import tables
import types, utils

template `@`(param: string): untyped =
  if param in pms: pms[param]
  else: ""

proc initQuery*(pms: Table[string, string]): Query =
  result = Query(
    iface: parseIface(@"iface"),
    withCaptive: if @"captive" == "1": true else: false
  )