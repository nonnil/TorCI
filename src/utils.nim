template test*(nim: untyped) =
  when defined test:
    nim

template test*(nim: untyped) =
  when defined test:
    nim
  else:
    quit(QuitFailure)