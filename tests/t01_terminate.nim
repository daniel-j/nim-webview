import webview

## =================================================================
## TEST: start app loop and terminate it.
## =================================================================

proc test_terminate() =
  echo "creating a webview"
  let w = newWebview(false, nil)
  echo "dispatching a callback"
  w.dispatch(proc () =
    echo "terminating"
    w.terminate()
  )
  echo "running main loop"
  w.run()
  echo "destroying webview"
  w.destroy()

test_terminate()
