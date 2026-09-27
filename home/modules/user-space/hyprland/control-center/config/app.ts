import GLib from "gi://GLib"
import app from "ags/gtk4/app"
import style from "./style.scss"
import ControlCenter from "./widget/ControlCenter"
import Overlay from "./widget/Overlay"

app.start({
  css: style,
  main() {
    const varsPath = GLib.get_user_config_dir() + "/ags/vars.css"
    app.apply_css(varsPath)

    ControlCenter()
    Overlay()
  },
  requestHandler(msg: string, res: (response: string) => void) {
    if (msg === "toggle") {
      const cc = app.get_window("control-center")
      const overlay = app.get_window("control-center-overlay")
      if (cc) cc.visible = !cc.visible
      if (overlay) overlay.visible = cc?.visible ?? false
      res("ok")
    } else if (msg === "quit") {
      app.quit()
      res("ok")
    } else {
      res("unknown command")
    }
  },
})
