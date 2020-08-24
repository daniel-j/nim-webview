import webview

## =================================================================
## TEST: start app loop and terminate it.
## =================================================================

proc test_terminate() =
  let w = newWebview(false, nil)
  defer: w.destroy()
  w.dispatch(proc () = w.terminate())
  w.run()

test_terminate()
