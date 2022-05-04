import std / [ unittest, asyncdispatch, terminal ]
import results, resultutils
import ../ ../ ../ src / lib / sys

suite "system in Docker container":
  test "getting system info...":
    match waitFor getSystemInfo():
      Ok(info):
        check:
          info.architecture.len > 0

      Err(msg):
        styledEcho fgRed, "[Err] ", fgWhite, msg