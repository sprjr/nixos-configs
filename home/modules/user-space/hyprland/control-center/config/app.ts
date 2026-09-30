import GLib from "gi://GLib"
import app from "ags/gtk4/app"
import style from "./style.scss"
import ControlCenter from "./widget/ControlCenter"
import HwMonitor from "./widget/HwMonitor"
import Overlay, { PANELS } from "./widget/Overlay"

// Show `name` and hide the other panels, or hide it if already visible.
function togglePanel(name: string) {
  const target = app.get_window(name)
  const show = !target?.visible
  for (const panel of PANELS) {
    const win = app.get_window(panel)
    if (win) win.visible = show && panel === name
  }
  const overlay = app.get_window("control-center-overlay")
  if (overlay) overlay.visible = show
}

app.start({
  css: style,
  main() {
    const varsPath = GLib.get_user_config_dir() + "/ags/vars.css"
    app.apply_css(varsPath)

    ControlCenter()
    HwMonitor()
    Overlay()
  },
  requestHandler(argv: string[], res: (response: string) => void) {
    const [msg] = argv
    if (msg === "toggle") {
      togglePanel("control-center")
      res("ok")
    } else if (msg === "toggle-hw") {
      togglePanel("hw-monitor")
      res("ok")
    } else if (msg === "quit") {
      app.quit()
      res("ok")
    } else {
      res("unknown command")
    }
  },
})
