import webview

## =================================================================
## TEST: use C API to create a window, run app and terminate it.
## =================================================================

proc cb_assert_arg(w: webview_t, arg: pointer) {.cdecl.} =
  assert(w != nil)
  let str = cast[cstring](arg)
  assert(str == "arg")
  echo "argument matched the expectated value"

proc cb_terminate(w: webview_t, arg: pointer) {.cdecl.} =
  assert(arg == nil);
  echo "terminating"
  webview_terminate(w)

proc test_c_api() =
  echo "creating webview"
  let w = webview_create(false.cint, nil)
  defer:
    echo "destroying webview"
    webview_destroy(w)
  echo "setting size"
  webview_set_size(w, 480, 320, 0)
  echo "setting title"
  webview_set_title(w, "Test")
  echo "navigating"
  webview_navigate(w, "https://github.com/zserge/webview")
  echo "dispatching callback with argument"
  webview_dispatch(w, cb_assert_arg, cast[pointer]("arg".cstring))
  echo "dispatching terminate"
  webview_dispatch(w, cb_terminate, nil)
  echo "running main loop"
  webview_run(w)
  echo "main loop ended"

test_c_api()
