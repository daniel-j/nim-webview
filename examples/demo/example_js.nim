import dom
import jsffi
import asyncjs
import math

proc then[T](p: PromiseJs, resolve: proc(val:T): PromiseJs|JsObject): PromiseJs {.importcpp, discardable, used.}
proc then[T](p: PromiseJs, resolve: proc(val:T)): PromiseJs {.importcpp, discardable, used.}

proc test(data: JsObject = nil): PromiseJs {.importc, discardable.}
proc externalNavigate(data: JsObject): PromiseJs {.importc, discardable.}
proc downloadFile(url: cstring): PromiseJs {.importc, discardable.}

proc updateProgress(progress, total, speed: int) {.exportc.} =
  let downloadProgress = document.getElementById("downloadProgress")
  downloadProgress.value = $progress
  downloadProgress.setAttribute("max", $total)
  let downloadProgressStatus = document.getElementById("downloadProgressStatus")
  downloadProgressStatus.textContent = $round(float(progress / total) * 100) & "%"

test(JsObject{"data": [1, 2, 3]}).then(proc (val: cstring) =
  echo "got something: ", val
)

window.addEventListener("DOMContentLoaded", (proc (_: Event) =
  document.addEventListener("click", (proc (ev: Event) =
    let href = ev.target.getAttribute("href")
    if not href.isNull:
      ev.preventDefault()
      ev.stopPropagation()
      var target = ev.target.getAttribute("target")
      if target.isNull:
        target = "_self"
      externalNavigate(JsObject{"href": href, "target": target})
  ), true)

  document.getElementById("btn10MB").onclick = proc (_: Event) =
    downloadFile("http://speedtest.tele2.net/10MB.zip").then(proc (val: JsObject) =
      echo "got length: ", val["length"].to(int)
    )
  document.getElementById("btn100MB").onclick = proc (_: Event) =
    downloadFile("http://speedtest.tele2.net/100MB.zip")
))
