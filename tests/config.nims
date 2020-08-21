switch("path", "$projectDir/../src")

# switch("cc", "clang")

when defined(macosx):
  switch("cc", "clang")
elif defined(windows) and not defined(mingw):
  switch("cc", "vcc")
