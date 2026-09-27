import app from "ags/gtk4/app"
import Astal from "gi://Astal?version=4.0"

function dismiss() {
  const cc = app.get_window("control-center")
  const overlay = app.get_window("control-center-overlay")
  if (cc) cc.visible = false
  if (overlay) overlay.visible = false
}

export default function Overlay() {
  const { TOP, BOTTOM, LEFT, RIGHT } = Astal.WindowAnchor

  return (
    <window
      visible={false}
      name="control-center-overlay"
      namespace="control-center-overlay"
      anchor={TOP | BOTTOM | LEFT | RIGHT}
      layer={Astal.Layer.TOP}
      keymode={Astal.Keymode.NONE}
      css="background: transparent;"
      application={app}
    >
      <button
        hexpand
        vexpand
        css="background: transparent; border: none; min-height: 0; min-width: 0; padding: 0;"
        onClicked={() => dismiss()}
      />
    </window>
  )
}
