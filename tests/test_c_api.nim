import webview

## =================================================================
## TEST: use C API to create a window, run app and terminate it.
## =================================================================

proc cb_assert_arg(w: webview_t, arg: pointer) {.cdecl.} =
  assert(w != nil)
  let str = cast[cstring](arg)
  assert(str == "arg")

proc cb_terminate(w: webview_t, arg: pointer) {.cdecl.} =
  assert(arg == nil);
  webview_terminate(w)

proc test_c_api() =
  let w = webview_create(false.cint, nil)
  webview_set_size(w, 480, 320, 0)
  webview_set_title(w, "Test")
  webview_navigate(w, "https://github.com/zserge/webview")
  webview_dispatch(w, cb_assert_arg, cast[pointer]("arg".cstring))
  webview_dispatch(w, cb_terminate, nil)
  webview_run(w)
  webview_destroy(w)

test_c_api()
