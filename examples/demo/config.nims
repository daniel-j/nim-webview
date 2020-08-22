switch("path", "../../src")

when not defined(js):
  switch("threads", "on")

  when defined(macosx):
    switch("cc", "clang")
  elif defined(windows) and not defined(mingw):
    switch("cc", "vcc")
