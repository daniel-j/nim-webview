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
  exec "nimble js -d:js examples/demo/example_js.nim"
  setCommand "compile", "examples/demo/example.nim"

task examplesmingw, "examples (mingw)":
  exec "nimble js -d:js examples/demo/example_js.nim"
  exec "WINEPATH=webview/dll/x64 nimble compile -d:mingw examples/demo/example.nim"
