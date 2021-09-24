import tables
import types, utils

template `@`(param: string): untyped =
  if param in pms: pms[param]
  else: ""

proc initQuery*(pms: Table[string, string]): Query =
  result = Query(
    iface: parseIface(@"i"),
    isCaptive: if @"t" == "captive": true else: false
  )