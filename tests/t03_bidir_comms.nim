import webview
import json

## =================================================================
## TEST: ensure that JS code can call native code and vice versa.
## =================================================================

proc test_bidir_comms() =
  echo "creating webview"
  let browser = newWebview(true, nil)
  defer:
    echo "destroying webview"
    browser.destroy()

  echo "binding invoke handler"
  browser.bind("invoke", proc (arg: JsonNode) =
    echo "invoke callback called with argument ", arg
    let i = arg[0].getInt()
    let msg = arg[1].getStr()
    echo msg
    case i
    of 0:
      assert(msg == "loaded")
      echo "evaluating js code"
      browser.eval("""invoke(1, "exiting " + window.x)""")
    of 1:
      assert(msg == "exiting 42")
      echo "terminating"
      browser.terminate()
    else:
      assert(false)
  )

  echo "adding init js code"
  browser.init("""
    window.x = 42;
    window.onload = () => {
      invoke(0, "loaded")
    };
  """)
  echo "navigating"
  browser.navigate("data:text/html,%3Chtml%3Ehello%3C%2Fhtml%3E")
  echo "running main loop"
  browser.run()
  echo "main loop ended"

test_bidir_comms()
