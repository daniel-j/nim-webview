import webview
import webview/utils
import json
import httpclient
import os
import strutils
import threadpool

echo "starting"

let w = newWebview(debug = true)

w.setSize(800, 600)
w.setTitle("Webview Example")

w.init("""console.log("init code")""")

w.setBorderless(false)

w.bind("webviewLoaded", proc (args: JsonNode): JsonNode =
  echo "load event!"
)

proc onProgressChanged(total, progress, speed: BiggestInt) =
  echo("Downloaded ", progress, " of ", total)
  echo("Current rate: ", speed div 1000, "kb/s")
  {.gcsafe.}:
    w.dispatch(proc() = w.eval("updateProgress(" & $ progress & ", " & $total &
        ", " & $speed & ")"))

w.bind("downloadFile", proc (id: string, args: JsonNode) =
  let url = args[0].getStr()
  echo "Downloading url in a separate thread: ", url

  spawn (proc (w: Webview, id: string, url: string) =
    # dispatch is required when calling eval etc. from other thread
    w.dispatch(proc () = w.eval("updateProgress(0, 1, 0)"))
    var client = newHttpClient()
    client.onProgressChanged = onProgressChanged
    let content = client.getContent(url)
    echo "Bytes downloaded: ", content.len
    w.dispatch(proc () =
      w.eval("updateProgress(" & $ content.len & ", " & $content.len & ", 0)")
      w.`return`(id, true, %* {"length": content.len})
    )
  )(w, id, url)
)

w.init("window.addEventListener('load', function (e) {webviewLoaded()}, false)")

w.bind("externalNavigate", proc (args: JsonNode): JsonNode =
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

w.dispatch(proc () = echo "DISPATCH")


var uri = "file://" & (getAppDir() / "main.html").replace($DirSep, "/")

if paramCount() >= 1:
  uri = paramStr(1)

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
