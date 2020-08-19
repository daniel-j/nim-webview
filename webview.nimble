# Package

version       = "0.1.0"
author        = "daniel-j"
description   = "Nim wrapper for the webview library"
license       = "MIT"
srcDir        = "src"

backend       = "cpp"

# Dependencies

requires "nim >= 1.0.0"

task example, "example":
  exec "nimble cpp --threads:on -d:ssl --app:gui example.nim"

task examplemingw, "example mingw":
  exec "WINEPATH=webview/dll/x64 nimble cpp --threads:on -d:ssl -d:mingw example.nim" # --app:gui
