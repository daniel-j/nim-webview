import webview
import os

let w = newWebview(debug = true)

w.setSize(800, 600)
w.setTitle("Webview Example")

var uri = "https://nim-lang.org"

if paramCount() >= 1:
  uri = paramStr(1)

echo uri

w.navigate(uri)

echo "running..."

w.run()

echo "completed"
w.destroy()
