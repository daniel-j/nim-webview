switch("path", "../../src")

switch("app", "gui")
switch("debugger", "native")

when defined(macosx):
  switch("cc", "clang")
elif defined(windows) and not defined(mingw):
  switch("cc", "vcc")
