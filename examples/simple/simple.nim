import webview

let w = newWebview(debug = true)

w.setSize(800, 600)
w.setTitle("Webview Example")

let uri = "https://nim-lang.org"
echo uri

w.navigate(uri)

echo "running..."

w.run()

echo "completed"
w.destroy()
