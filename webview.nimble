# Package

version       = "0.1.0"
author        = "djazz"
description   = "Nim wrapper for the webview library"
license       = "MIT"
srcDir        = "src"

backend       = "cpp"

# Dependencies

requires "nim >= 1.0.0"

task examples, "examples":
  exec "nimble js examples/demo/example_js.nim"
  when defined(linux):
    exec "nimble compile --app:console --threads:on --gc:arc examples/demo/example.nim"
  elif defined(macosx):
    exec "nimble compile --cc:clang --app:console --threads:on --gc:arc examples/demo/example.nim"
  elif defined(windows):
    exec "nimble compile --cc:vcc --app:console --threads:on --gc:arc examples/demo/example.nim"

task examplesmingw, "examples (mingw)":
  exec "nimble js examples/demo/example_js.nim"
  exec "WINEPATH=webview/dll/x64 nimble compile --app:console --threads:on --gc:arc -d:mingw examples/demo/example.nim"
