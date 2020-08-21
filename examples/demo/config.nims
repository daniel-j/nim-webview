switch("path", "../../src")

when not defined(js):
  switch("app", "console")
  switch("threads", "on")
  #switch("gc", "arc")
  switch("debugger", "native")
  when defined(macosx):
    switch("cc", "clang")
  elif defined(windows) and not defined(mingw):
    switch("cc", "vcc")
