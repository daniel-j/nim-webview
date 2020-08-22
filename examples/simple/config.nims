switch("path", "../../src")

when defined(macosx):
  switch("cc", "clang")
elif defined(windows) and not defined(mingw):
  switch("cc", "vcc")
