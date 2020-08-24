import webview

## =================================================================
## TEST: start app loop and terminate it.
## =================================================================

proc test_terminate() =
  echo "creating webview"
  let w = newWebview(false, nil)
  defer:
    echo "destroying webview"
    w.destroy()
  echo "dispatching a callback"
  w.dispatch(proc () =
    echo "terminating"
    w.terminate()
  )
  echo "running main loop"
  w.run()

test_terminate()
