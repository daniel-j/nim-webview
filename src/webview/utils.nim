import ../webview

func setBorderless*(w: Webview, borderless: bool) =
  when defined(linux):
    proc gtk_window_set_decorated(window: WebviewWindow, setting: bool) {.header: "<gtk/gtk.h>".}
    gtk_window_set_decorated(w.window, not borderless)
