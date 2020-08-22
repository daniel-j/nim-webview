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
  exec "nimble compile examples/demo/example.nim"
  exec "nimble compile examples/simple/simple.nim"

task examplesmingw, "examples (mingw)":
  exec "nimble js -d:js examples/demo/example_js.nim"
  exec "nimble compile -d:mingw examples/demo/example.nim"
  exec "nimble compile -d:mingw examples/simple/simple.nim"
