
import json
import hashes
import os

const inclDir = currentSourcePath() /../ "" /../ "webview"

when not (defined(windows) or defined(mingw)):
  {.passC: "-I" & inclDir.}

when not defined(mingw):
  {.compile: inclDir / "webview.cc".}

{.pragma: implwebview, importc, cdecl.}

when defined(linux):
  const libs = "gtk+-3.0 webkit2gtk-4.0"
  const (cflags, cflagscode) = gorgeEx("pkg-config --cflags " & libs)
  const (lflags, lflagscode) = gorgeEx("pkg-config --libs " & libs)
  static:
    if cflagscode != 0 or lflagscode != 0:
      echo cflags, "\n", lflags
      raise newException(OSError, "Required dependencies not found!")
  {.passC: "-DWEBVIEW_GTK=1 " & cflags, passL: "-static-libstdc++ -static-libgcc " & lflags.}
elif defined(windows):
  when defined(mingw):
    import strutils
    const dllDir = inclDir / "dll" / "x64"
    {.passL: "-L" & dllDir.replace($DirSep, "/").}
    {.passC: "-DWEBVIEW_WINAPI=1 -DWEBVIEW_HEADER=1 -I" & inclDir.replace($DirSep, "/"), passL: "-static-libstdc++ -static-libgcc -Wl,-Bstatic -lstdc++ -lpthread -Wl,-Bdynamic -mwindows -lwebview -lWebView2Loader".}
  else:
    const webview2Dir = inclDir / "script" / "microsoft.web.webview2.1.0.664.37" / "build" / "native" / "include"
    const webview2Lib = inclDir / "script" / "microsoft.web.webview2.1.0.664.37" / "build" / "native" / "x64" / "WebView2Loader.dll.lib"
    {.passC: "/DWEBVIEW_WINAPI=1 /std:c++17 /I" & inclDir & " /I" & webview2Dir, passL: webview2Lib.}
elif defined(macosx):
  {.passC: "-DWEBVIEW_COCOA=1", passL: "-framework WebKit".}

type
  webview_t* = pointer
  WebviewWindow* = pointer

  Webview* = object
    w*: webview_t
    debug*: bool
    window*: WebviewWindow
    bindArgs: seq[BindArg]

  Hint* {.size: sizeof(cint).} = enum None, Min, Max, Fixed

  DispatchCallback* = proc ()
  DispatchArg = ref tuple[fn: DispatchCallback]
  BindCallback* = proc (id: string, args: JsonNode)
  BindCallbackReturn* = proc (args: JsonNode): JsonNode
  BindCallbackNoReturn* = proc (args: JsonNode)
  BindArg = ref tuple[w: Webview, name: cstring, fn: BindCallback]
  

proc webview_create*(debug: cint; window: pointer): webview_t {.implwebview.}
  ## ```
  ##   Creates a new webview instance. If debug is non-zero - developer tools will
  ##      be enabled (if the platform supports them). Window parameter can be a
  ##      pointer to the native window handle. If it's non-null - then child WebView
  ##      is embedded into the given parent window. Otherwise a new window is created.
  ##      Depending on the platform, a GtkWindow, NSWindow or HWND pointer can be
  ##      passed here.
  ## ```
proc webview_destroy*(w: webview_t) {.implwebview.}
  ## ```
  ##   Destroys a webview and closes the native window.
  ## ```
proc webview_run*(w: webview_t) {.implwebview.}
  ## ```
  ##   Runs the main loop until it's terminated. After this function exits - you
  ##      must destroy the webview.
  ## ```
proc webview_terminate*(w: webview_t) {.implwebview.}
  ## ```
  ##   Stops the main loop. It is safe to call this function from another other
  ##      background thread.
  ## ```
proc webview_dispatch*(w: webview_t; fn: proc (w: webview_t, arg: pointer) {.cdecl.}; arg: pointer) {.implwebview.}
  ## ```
  ##   Posts a function to be executed on the main thread. You normally do not need
  ##      to call this function, unless you want to tweak the native window.
  ## ```
proc webview_get_window*(w: webview_t): pointer {.implwebview.}
  ## ```
  ##   Returns a native window handle pointer. When using GTK backend the pointer
  ##      is GtkWindow pointer, when using Cocoa backend the pointer is NSWindow
  ##      pointer, when using Win32 backend the pointer is HWND pointer.
  ## ```
proc webview_set_title*(w: webview_t; title: cstring) {.implwebview.}
  ## ```
  ##   Updates the title of the native window. Must be called from the UI thread.
  ## ```
proc webview_set_size*(w: webview_t; width: cint; height: cint; hints: cint) {.implwebview.}
  ## ```
  ##   Updates native window size. See WEBVIEW_HINT constants.
  ## ```
proc webview_navigate*(w: webview_t; url: cstring) {.implwebview.}
  ## ```
  ##   Navigates webview to the given URL. URL may be a data URI, i.e.
  ##      "data:text/text,<html>...</html>". It is often ok not to url-encode it
  ##      properly, webview will re-encode it for you.
  ## ```
proc webview_init*(w: webview_t; js: cstring) {.implwebview.}
  ## ```
  ##   Injects JavaScript code at the initialization of the new page. Every time
  ##      the webview will open a the new page - this initialization code will be
  ##      executed. It is guaranteed that code is executed before window.onload.
  ## ```
proc webview_eval*(w: webview_t; js: cstring) {.implwebview.}
  ## ```
  ##   Evaluates arbitrary JavaScript code. Evaluation happens asynchronously, also
  ##      the result of the expression is ignored. Use RPC bindings if you want to
  ##      receive notifications about the results of the evaluation.
  ## ```
proc webview_bind*(w: webview_t; name: cstring; fn: proc (id: cstring, req: cstring, arg: pointer) {.cdecl.}; arg: pointer) {.implwebview.}
  ## ```
  ##   Binds a native C callback so that it will appear under the given name as a
  ##      global JavaScript function. Internally it uses webview_init(). Callback
  ##      receives a request string and a user-provided argument pointer. Request
  ##      string is a JSON array of all the arguments passed to the JavaScript
  ##      function.
  ## ```
proc webview_return*(w: webview_t; id: cstring; status: cint; result: cstring) {.implwebview.}
  ## ```
  ##   Allows to return a value from the native binding. Original request pointer
  ##      must be provided to help internal RPC engine match requests with responses.
  ##      If status is zero - result is expected to be a valid JSON result value.
  ##      If status is not zero - result is an error JSON object.
  ## ```

proc hash*(w: Webview): Hash = w.w.hash

proc newWebview*(debug: bool = true, window: pointer = nil): Webview =
  result.debug = debug
  result.w = webview_create(debug.cint, window)
  result.window = result.w.webview_get_window()

proc destroy*(w: Webview) =
  for bindArg in w.bindArgs:
    GC_unref(bindArg)
  w.w.webview_destroy()

proc terminate*(w: Webview) =
  w.w.webview_terminate()

proc getWindow*(w: Webview): WebviewWindow =
  w.w.webview_get_window()

proc init*(w: Webview, js: string) =
  w.w.webview_init(js)

proc setTitle*(w: Webview, title: string) =
  w.w.webview_set_title(title)

proc setSize*(w: Webview, width: Positive, height: Positive, hints: Hint = None) =
  w.w.webview_set_size(width.cint, height.cint, hints.cint)

proc navigate*(w: Webview, url: string) =
  w.w.webview_navigate(url)

proc run*(w: Webview) =
  w.w.webview_run()

proc generalDispatchProc(_: webview_t, arg: pointer) {.gcsafe, cdecl.} =
  let dispatchArg = cast[DispatchArg](arg)
  let fn = dispatchArg.fn
  defer: GC_unref(dispatchArg)
  {.gcsafe.}:
    fn()

proc dispatch*(w: Webview; fn: DispatchCallback) {.gcsafe.} =
  let dispatchArg = new(DispatchArg)
  dispatchArg.fn = fn

  GC_ref(dispatchArg)
  w.w.webview_dispatch(generalDispatchProc, cast[pointer](dispatchArg))

proc eval*(w: Webview, js: string) {.gcsafe.} =
  w.w.webview_eval(js)

proc `return`*(w: Webview, id: string, success: bool, result: JsonNode) =
  if result.isNil:
    # echo "return: nil"
    w.w.webview_return(id, (not success).cint, "null")
  else:
    # echo "return: " & $result
    w.w.webview_return(id, (not success).cint, $result)


proc generalBindProc(id: cstring, req: cstring, arg: pointer) {.cdecl.} =
  let bindArg = cast[BindArg](arg)
  let fn = bindArg.fn

  let args = parseJson($req)
  fn($id, args)

proc `bind`*(w: Webview, name: cstring, fn: BindCallback) =
  let bindArg = new(BindArg)
  bindArg.w = w
  bindArg.name = name
  bindArg.fn = fn

  GC_ref(bindArg)
  w.w.webview_bind(name, generalBindProc, cast[pointer](bindArg))

proc `bind`*(w: Webview, name: cstring, fn: BindCallbackReturn) =
  w.`bind`(name, proc (id: string, args: JsonNode) =
    let res = fn(args)
    w.return(id, true, res)
  )

proc `bind`*(w: Webview, name: cstring, fn: BindCallbackNoReturn) =
  w.`bind`(name, proc (id: string, args: JsonNode) =
    fn(args)
    w.return(id, true, nil)
  )
