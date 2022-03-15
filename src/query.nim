import std / [ options, tables ]

import lib / sys / iface

type
  Query* = ref object
    iface*: IfaceKind
    withCaptive*: bool

template `@`(param: string): untyped =
  if param in pms: pms[param]
  else: ""

proc initQuery*(pms: Table[string, string]): Query =
  result = Query(
    iface: parseIfaceKind(@"iface").get,
    withCaptive: if @"captive" == "1": true else: false
  )