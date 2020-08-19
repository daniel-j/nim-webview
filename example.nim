import src/webview
import json
import asyncdispatch
import httpclient
import os

echo "starting"

let w = newWebview(debug=true)
defer: w.destroy()

w.setSize(800, 600)
w.setTitle("Webview Example")

echo repr(w)

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

w.bind("webviewLoaded", proc (args: JsonNode): Future[JsonNode] {.async, thread.} =
  echo "load event!"
)

proc onProgressChanged(total, progress, speed: BiggestInt) {.async, thread.} =
  echo("Downloaded ", progress, " of ", total)
  echo("Current rate: ", speed div 1000, "kb/s")
  # w.dispatch(proc () = w.eval("console.log(" & $ %* @[progress, total]  & ")"))

w.bind("test", proc (args: JsonNode): Future[JsonNode] {.async, thread.} =
  echo "test! ", args.getElems
  var client = newAsyncHttpClient()
  client.onProgressChanged = onProgressChanged
  let content = await client.getContent("http://speedtest.tele2.net/10MB.zip")
  echo "got content ", content.len
  return %* {"length": content.len}
)

w.init("window.addEventListener('load', function (e) {webviewLoaded()}, false)")

w.bind("externalNavigate", proc(args: JsonNode): Future[JsonNode] {.async, thread.} =
  let url:string = $args[0]
  echo url
)

w.bind("simple", proc (args: JsonNode) {.thread.} =
  echo "simple bind! no return value"
)

w.bind("terminate", proc (args: JsonNode) {.thread.} =
  w.terminate()
)

w.dispatch(proc () = echo "DISPATCH")



w.navigate("file://" & getCurrentDir() / "example.html")

#[
var
  running = true
  thr: Thread[void]
  waiting = false

proc threadFunc() {.thread.} =
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
