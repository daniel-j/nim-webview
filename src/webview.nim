
import json
import asyncdispatch
import threadpool
import tables
import hashes

when not (defined(windows) and defined(mingw)):
  {.compile: "../webview/webview.cc".}

when defined(linux):
  const libs = "gtk+-3.0 webkit2gtk-4.0"
  const (cflags, cflagscode) = gorgeEx("pkg-config --cflags " & libs)
  const (lflags, lflagscode) = gorgeEx("pkg-config --libs " & libs)
  static:
    if cflagscode != 0 or lflagscode != 0:
      echo cflags, "\n", lflags
      raise newException(OSError, "Required dependencies not found!")
  {.passC: "-DWEBVIEW_GTK=1 " & cflags, passL: lflags.}
elif defined(windows):
  if defined(mingw):
    {.passC: "-DWEBVIEW_WINAPI=1", passL: "-static-libstdc++ -static-libgcc -Wl,-Bstatic -lstdc++ -lpthread -Wl,-Bdynamic -mwindows -L./webview/dll/x64 -lwebview -lWebView2Loader".}
  else:
    {.passC: "-DWEBVIEW_WINAPI=1", passL: "-mwindows -L./webview/dll/x64 -lwebview -lWebView2Loader".}
elif defined(macosx):
  {.passC: "-DWEBVIEW_COCOA=1 -x objective-c", passL: "-std=c++11 -framework WebKit".}


type
  webview_t* = pointer
  Webview = object
    w*: webview_t
    debug*: bool
    window*: pointer
  Hint* {.size: sizeof(cint).} = enum None, Min, Max, Fixed

  DispatchCallback* = proc ()
  DispatchArg = ref tuple[fn: DispatchCallback]
  BindCallback* = proc (args: JsonNode): Future[JsonNode]
  BindSimpleCallback* = proc (args: JsonNode)
  BindArg = ref tuple[w: webview_t, name: cstring]

var
  dispatchTable = newTable[Hash, (DispatchCallback, DispatchArg)]()
  bindTable = newTable[Hash, (BindCallback, BindArg)]()

proc create(debug: cint = 0; window: pointer): webview_t {.importc: "webview_create".}
  ## ```
  ##   Creates a new webview instance. If debug is non-zero - developer tools will
  ##      be enabled (if the platform supports them). Window parameter can be a
  ##      pointer to the native window handle. If it's non-null - then child WebView
  ##      is embedded into the given parent window. Otherwise a new window is created.
  ##      Depending on the platform, a GtkWindow, NSWindow or HWND pointer can be
  ##      passed here.
  ## ```
proc destroy(w: webview_t) {.importc: "webview_destroy".}
  ## ```
  ##   Destroys a webview and closes the native window.
  ## ```
proc run(w: webview_t) {.importc: "webview_run".}
  ## ```
  ##   Runs the main loop until it's terminated. After this function exits - you
  ##      must destroy the webview.
  ## ```
proc terminate(w: webview_t) {.importc: "webview_terminate".}
  ## ```
  ##   Stops the main loop. It is safe to call this function from another other
  ##      background thread.
  ## ```
proc dispatch(w: webview_t; fn: pointer; arg: pointer) {.importc: "webview_dispatch".}
  ## ```
  ##   Posts a function to be executed on the main thread. You normally do not need
  ##      to call this function, unless you want to tweak the native window.
  ## ```
proc get_window(w: webview_t): pointer {.importc: "webview_get_window".}
  ## ```
  ##   Returns a native window handle pointer. When using GTK backend the pointer
  ##      is GtkWindow pointer, when using Cocoa backend the pointer is NSWindow
  ##      pointer, when using Win32 backend the pointer is HWND pointer.
  ## ```
proc set_title(w: webview_t; title: cstring) {.importc: "webview_set_title".}
  ## ```
  ##   Updates the title of the native window. Must be called from the UI thread.
  ## ```
proc set_size(w: webview_t; width: cint; height: cint; hints: cint) {.importc: "webview_set_size".}
  ## ```
  ##   Updates native window size. See WEBVIEW_HINT constants.
  ## ```
proc navigate(w: webview_t; url: cstring) {.importc: "webview_navigate".}
  ## ```
  ##   Navigates webview to the given URL. URL may be a data URI, i.e.
  ##      "data:text/text,<html>...</html>". It is often ok not to url-encode it
  ##      properly, webview will re-encode it for you.
  ## ```
proc init(w: webview_t; js: cstring) {.importc: "webview_init".}
  ## ```
  ##   Injects JavaScript code at the initialization of the new page. Every time
  ##      the webview will open a the new page - this initialization code will be
  ##      executed. It is guaranteed that code is executed before window.onload.
  ## ```
proc eval(w: webview_t; js: cstring) {.importc: "webview_eval".}
  ## ```
  ##   Evaluates arbitrary JavaScript code. Evaluation happens asynchronously, also
  ##      the result of the expression is ignored. Use RPC bindings if you want to
  ##      receive notifications about the results of the evaluation.
  ## ```
proc `bind`(w: webview_t; name: cstring; fn: pointer; arg: pointer) {.importc: "webview_bind".}
  ## ```
  ##   Binds a native C callback so that it will appear under the given name as a
  ##      global JavaScript function. Internally it uses webview_init(). Callback
  ##      receives a request string and a user-provided argument pointer. Request
  ##      string is a JSON array of all the arguments passed to the JavaScript
  ##      function.
  ## ```
proc `return`(w: webview_t; `seq`: cstring; status: cint; result: cstring) {.importc: "webview_return".}
  ## ```
  ##   Allows to return a value from the native binding. Original request pointer
  ##      must be provided to help internal RPC engine match requests with responses.
  ##      If status is zero - result is expected to be a valid JSON result value.
  ##      If status is not zero - result is an error JSON object.
  ## ```

proc newWebview*(debug: bool = true, window: pointer = nil): Webview =
  result.debug = debug
  result.w = create(debug.cint, window)
  result.window = result.w.get_window()

proc destroy*(w: Webview) =
  w.w.destroy()

proc terminate*(w: Webview) =
  w.w.terminate()

proc get_window*(w: Webview): pointer =
  w.w.get_window()

proc init*(w: Webview, js: string) =
  w.w.init(js)

proc eval*(w: Webview, js: string) =
  w.w.eval(js)

proc set_title*(w: Webview, title: string) =
  w.w.set_title(title)

proc set_size*(w: Webview, width: Positive, height: Positive, hints: Hint = None) =
  w.w.set_size(width.cint, height.cint, hints.cint)

proc navigate*(w: Webview, url: string) =
  w.w.navigate(url)

proc run*(w: Webview, sync = false) =
  w.w.run()
  if sync:
    sync()


proc globalDispatchProc*(w: webview_t, arg: pointer) =
  let dispatchArg = cast[DispatchArg](arg)
  let key = dispatchArg[].hash
  let (fn, _) = dispatchTable[key]
  fn()
  GC_unref(dispatchArg)
      

proc dispatch(w: webview_t; fn: DispatchCallback) {.thread.} =
  {.gcsafe.}:
    let dispatchArg = new(DispatchArg)
    dispatchArg.fn = fn
    let key = dispatchArg[].hash
    dispatchTable[key] = (fn, dispatchArg)
    GC_ref(dispatchArg)
    w.dispatch(globalDispatchProc, cast[pointer](dispatchArg))

proc dispatch*(w: Webview; fn: DispatchCallback) =
  w.w.dispatch(fn)

proc `return`(w: webview_t, `seq`: string, success: bool, result: JsonNode) =
  if result.isNil:
    # echo "return: nil"
    w.return(`seq`, (not success).cint, "null")
  else:
    # echo "return: " & $result
    w.return(`seq`, (not success).cint, $result)

proc bindThread(w: webview_t, name: cstring, fn: BindCallback, req: string, `seq`: string) {.thread.} =
  echo "callback " & $name & " running in thread: " & $getThreadId()
  try:
    let args = parseJson(req)
    let futureData = fn(args)
    let data = waitFor(futureData)
    let res = %* data
    GC_ref(res)
    w.dispatch(proc() = w.return(`seq`, true, res); GC_unref(res))
  except:
    w.dispatch(proc() = w.return(`seq`, false, %* {"error": repr(getCurrentException()), "message": getCurrentExceptionMsg()}))
    echo "Got exception ", repr(getCurrentException()), " with message ", getCurrentExceptionMsg()

proc generalBindProc(`seq`: cstring; req: cstring; arg: pointer) =
  let bindArg = cast[BindArg](arg)
  let key = bindArg[].hash
  let (fn, _) = bindTable[key]
  echo repr bindArg
  echo isNil fn
  spawn(bindThread(bindArg.w, bindArg.name, fn, $req, $`seq`))

proc `bind`*(w: Webview, name: cstring, fn: BindCallback) =
  let bindArg = new(BindArg)
  bindArg.w = w.w
  bindArg.name = name
  let key = bindArg[].hash
  if key in bindTable:
    echo "bind function " & $name & " already exist for this webview!"
    return
  bindTable[key] = (fn, bindArg)

  GC_ref(bindArg)

  w.w.`bind`(name, generalBindProc, cast[pointer](bindArg))

proc `bind`*(w: Webview, name: cstring, fn: BindSimpleCallback) =
  w.`bind`(name, proc (args: JsonNode): Future[JsonNode] {.async.} = fn(args))
