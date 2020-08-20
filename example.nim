import src/webview
import json
import httpclient
import os

echo "starting"

let w = newWebview(debug=true)

w.setSize(800, 600)
w.setTitle("Webview Example")

w.init("""console.log("init code")""")


#[
w.`bind`("test", proc (`seq`: cstring; req: cstring; arg: pointer) =
  echo "test success!"
  echo `seq`
  echo parseJson $req
  echo repr arg
  w.return(`seq`, 0, "[12345, 4567]")
)
]#

w.bind("webviewLoaded", proc (args: JsonNode): JsonNode =
  echo "load event!"
)

proc onProgressChanged(total, progress, speed: BiggestInt) =
  echo("Downloaded ", progress, " of ", total)
  echo("Current rate: ", speed div 1000, "kb/s")
  {.gcsafe.}:
    w.dispatch(proc () = w.eval("updateProgress(" & $ progress & ", " & $total & ")"))

w.bind("downloadFile", proc (args: JsonNode): JsonNode =
  let url = args[0].getStr()
  echo "Downloading url: ", url
  var client = newHttpClient()
  client.onProgressChanged = onProgressChanged
  let content = client.getContent(url)
  echo "Bytes downloaded: ", content.len
  {.gcsafe.}:
    w.dispatch(proc () = w.eval("updateProgress(" & $ content.len & ", " & $content.len & ")"))
  return %* {"length": content.len}
)

w.init("window.addEventListener('load', function (e) {webviewLoaded()}, false)")

w.bind("externalNavigate", proc(args: JsonNode): JsonNode =
  echo "clicked something with a href!"
  let href = args[0]["href"]
  let target = args[0]["target"]
  echo "href: ", href
  echo "target: ", target
)

w.bind("simple", proc (args: JsonNode) =
  echo "simple bind! no return value"
)

w.bind("test", proc (args: JsonNode): JsonNode =
  echo "test! ", args

  return %* "a response"
)

w.bind("terminate", proc (args: JsonNode) =
  w.terminate()
)

# w.dispatch(proc () = echo "DISPATCH")


let uri = "file://" & getCurrentDir() / "example.html"
echo uri

w.navigate(uri)

#[
var
  running = true
  thr: Thread[void]
  waiting = false

proc threadFunc() =
  sleep(20)
  while running:
    if not waiting:
      waiting = true
      w.dispatch(proc () =
        let start = cpuTime()
        var c = 0

        while hasPendingOperations() and cpuTime() - start < 0.0015:
          poll(10)
          inc c
        if c > 0:
          echo c, " ", cpuTime() - start
        waiting = false
      )
      sleep(1)
    else:
      sleep(1)

spawn (proc () =
  # w.dispatch(proc() = echo 1)
  while running:
    w.dispatch(proc () =
      if hasPendingOperations():
        poll(20)
    )
    sleep(5)
)()

createThread(thr, threadFunc)
]#

echo "running..."

w.run()

# running = false
# echo "syncing thread..."
# joinThread(thr)

echo "completed"
w.destroy()
