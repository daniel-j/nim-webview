
import json
import asyncdispatch
import threadpool
import tables

when not (defined(windows) and defined(mingw)):
  {.compile: "../webview/webview.cc".}

when defined(linux):
  {.passC: "-DWEBVIEW_GTK=1 " & staticExec"pkg-config --cflags gtk+-3.0 webkit2gtk-4.0", passL: staticExec"pkg-config --libs gtk+-3.0 webkit2gtk-4.0".}
elif defined(windows):
  if defined(mingw):
    {.passC: "-DWEBVIEW_WINAPI=1", passL: "-static-libstdc++ -static-libgcc -Wl,-Bstatic -lstdc++ -lpthread -Wl,-Bdynamic -mwindows -L./webview/dll/x64 -lwebview -lWebView2Loader".}
  else:
    {.passC: "-DWEBVIEW_WINAPI=1", passL: "-mwindows -L./webview/dll/x64 -lwebview -lWebView2Loader".}
elif defined(macosx):
  {.passC: "-DWEBVIEW_COCOA=1 -x objective-c", passL: "-std=c++11 -framework WebKit".}


type
  Webview* = pointer
  Hint* {.size: sizeof(cint).} = enum None, Min, Max, Fixed
  BindCallback = proc (args: JsonNode): Future[JsonNode]
  BindSimpleCallback = proc (args: JsonNode)
  BindArg = ref tuple[w: Webview, name: cstring]

var bindTable = newTable[(Webview, cstring), BindCallback]()

proc create*(debug: cint = 0; window: pointer): Webview {.importc: "webview_create".}
  ## ```
  ##   Creates a new webview instance. If debug is non-zero - developer tools will
  ##      be enabled (if the platform supports them). Window parameter can be a
  ##      pointer to the native window handle. If it's non-null - then child WebView
  ##      is embedded into the given parent window. Otherwise a new window is created.
  ##      Depending on the platform, a GtkWindow, NSWindow or HWND pointer can be
  ##      passed here.
  ## ```
proc destroy*(w: Webview) {.importc: "webview_destroy".}
  ## ```
  ##   Destroys a webview and closes the native window.
  ## ```
proc run*(w: Webview) {.importc: "webview_run".}
  ## ```
  ##   Runs the main loop until it's terminated. After this function exits - you
  ##      must destroy the webview.
  ## ```
proc terminate*(w: Webview) {.importc: "webview_terminate".}
  ## ```
  ##   Stops the main loop. It is safe to call this function from another other
  ##      background thread.
  ## ```
proc dispatch*(w: Webview; fn: proc (w: Webview; arg: pointer); arg: pointer) {.importc: "webview_dispatch".}
  ## ```
  ##   Posts a function to be executed on the main thread. You normally do not need
  ##      to call this function, unless you want to tweak the native window.
  ## ```
proc get_window*(w: Webview): pointer {.importc: "webview_get_window".}
  ## ```
  ##   Returns a native window handle pointer. When using GTK backend the pointer
  ##      is GtkWindow pointer, when using Cocoa backend the pointer is NSWindow
  ##      pointer, when using Win32 backend the pointer is HWND pointer.
  ## ```
proc set_title*(w: Webview; title: cstring) {.importc: "webview_set_title".}
  ## ```
  ##   Updates the title of the native window. Must be called from the UI thread.
  ## ```
proc set_size*(w: Webview; width: cint; height: cint; hints: Hint = None) {.importc: "webview_set_size".}
  ## ```
  ##   Updates native window size. See WEBVIEW_HINT constants.
  ## ```
proc navigate*(w: Webview; url: cstring) {.importc: "webview_navigate".}
  ## ```
  ##   Navigates webview to the given URL. URL may be a data URI, i.e.
  ##      "data:text/text,<html>...</html>". It is often ok not to url-encode it
  ##      properly, webview will re-encode it for you.
  ## ```
proc init*(w: Webview; js: cstring) {.importc: "webview_init".}
  ## ```
  ##   Injects JavaScript code at the initialization of the new page. Every time
  ##      the webview will open a the new page - this initialization code will be
  ##      executed. It is guaranteed that code is executed before window.onload.
  ## ```
proc eval*(w: Webview; js: cstring) {.importc: "webview_eval".}
  ## ```
  ##   Evaluates arbitrary JavaScript code. Evaluation happens asynchronously, also
  ##      the result of the expression is ignored. Use RPC bindings if you want to
  ##      receive notifications about the results of the evaluation.
  ## ```
proc `bind`(w: Webview; name: cstring; fn: pointer; arg: pointer) {.importc: "webview_bind".}
  ## ```
  ##   Binds a native C callback so that it will appear under the given name as a
  ##      global JavaScript function. Internally it uses webview_init(). Callback
  ##      receives a request string and a user-provided argument pointer. Request
  ##      string is a JSON array of all the arguments passed to the JavaScript
  ##      function.
  ## ```
proc `return`*(w: Webview; `seq`: cstring; status: cint; result: cstring) {.importc: "webview_return".}
  ## ```
  ##   Allows to return a value from the native binding. Original request pointer
  ##      must be provided to help internal RPC engine match requests with responses.
  ##      If status is zero - result is expected to be a valid JSON result value.
  ##      If status is not zero - result is an error JSON object.
  ## ```

proc `return`*(w: Webview, `seq`: string, success: bool, result: JsonNode) =
  if result.isNil:
    # echo "return: nil"
    w.return(`seq`, (not success).cint, "null")
  else:
    # echo "return: " & $result
    w.return(`seq`, (not success).cint, $result)

proc dispatch*(w: Webview; fn: proc()) =
  w.dispatch(proc (w: Webview; arg: pointer) = fn(), nil)

proc bindThread(w: Webview, name: cstring, fn: BindCallback, req: string, `seq`: string) {.gcsafe.} =
  try:
    let args = parseJson(req)
    let futureData = fn(args)
    let data = waitFor(futureData)
    let res = %* data
    w.dispatch(proc() = w.return(`seq`, true, res))
  except:
    w.dispatch(proc() = w.return(`seq`, false, %* {"error": repr(getCurrentException()), "message": getCurrentExceptionMsg()}))
    echo "Got exception ", repr(getCurrentException()), " with message ", getCurrentExceptionMsg()

proc generalBindProc(`seq`: cstring; req: cstring; arg: pointer) =
  let key = cast[BindArg](arg)[]
  let fn = bindTable[key]
  spawn(bindThread(key.w, key.name, fn, $req, $`seq`))

proc `bind`*(w: Webview, name: cstring, fn: BindCallback) =
  let bindArg = new(BindArg)
  bindArg.w = w
  bindArg.name = name
  if bindArg[] in bindTable:
    echo "bind function " & $name & " already exists!"
    return
  bindTable[bindArg[]] = fn
  w.`bind`(name, generalBindProc, cast[pointer](bindArg))

proc `bind`*(w: Webview, name: cstring, fn: BindSimpleCallback) =
  w.`bind`(name, proc (args: JsonNode): Future[JsonNode] {.async.} = fn(args))
