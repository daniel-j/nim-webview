import dom
import jsffi
import asyncjs

proc then[T](p: PromiseJs, resolve: proc(val:T): PromiseJs|JsObject): PromiseJs {.importcpp, discardable.}
proc then[T](p: PromiseJs, resolve: proc(val:T)): PromiseJs {.importcpp, discardable.}

proc test(data: JsObject = nil): PromiseJs {.importc.}

proc externalNavigate(data: JsObject) {.importc.}

test(JsObject{"data": [1, 2, 3]}).then(proc (val: cstring) =
  echo "got something: ", val
)

proc updateProgress(progress, total: int) {.exportc.} =
  echo progress
  echo total
  let downloadProgress = document.getElementById("downloadProgress")
  downloadProgress.value = $progress
  downloadProgress.setAttribute("max", $total)

window.addEventListener("DOMContentLoaded", (proc (ev: Event) =
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
))
