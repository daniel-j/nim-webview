switch("path", "$projectDir/../src")

when defined(macosx):
  switch("cc", "clang")
elif defined(windows) and not defined(mingw):
  switch("cc", "clangcl")
