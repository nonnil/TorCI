import osproc, strutils

discard """
  
  output: '''
active
inactive
activating
'''

"""

proc isActive(name: string): string =
  const cmd = "sudo systemctl is-active "
  var ret = execCmdEx(cmd & name).output
  ret = splitLines(ret)[0]
  return ret

var ret: string  
ret = isActive "wpa_supplicant"
echo "result: ", "\"", ret, "\""
ret = isActive "nim"
echo "result: ", "\"", ret, "\""