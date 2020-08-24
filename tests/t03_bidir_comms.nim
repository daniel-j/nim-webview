import webview
import json

## =================================================================
## TEST: ensure that JS code can call native code and vice versa.
## =================================================================

proc test_bidir_comms() =
  let browser = newWebview(true, nil)

  browser.bind("invoke", proc (arg: JsonNode) =
    let i = arg[0].getInt()
    let msg = arg[1].getStr()
    echo msg
    case i
    of 0:
      assert(msg == "loaded")
      browser.eval("""invoke(1, "exiting " + window.x)""")
    of 1:
      assert(msg == "exiting 42")
      browser.terminate()
    else:
      assert(false)
  )

  browser.init("""
    window.x = 42;
    window.onload = () => {
      invoke(0, "loaded")
    };
  """)
  browser.navigate("data:text/html,%3Chtml%3Ehello%3C%2Fhtml%3E")
  browser.run()
  browser.destroy()

test_bidir_comms()
