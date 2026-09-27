import app from "ags/gtk4/app"
import Astal from "gi://Astal?version=4.0"
import Gtk from "gi://Gtk?version=4.0"
import Header from "./Header"
import Network from "./Network"
import Bluetooth from "./Bluetooth"
import Audio from "./Audio"
import Brightness from "./Brightness"
import PowerProfile from "./PowerProfile"
import Battery from "./Battery"
import Media from "./Media"

export default function ControlCenter() {
  const { TOP, RIGHT } = Astal.WindowAnchor

  return (
    <window
      visible={false}
      name="control-center"
      namespace="control-center"
      anchor={TOP | RIGHT}
      layer={Astal.Layer.TOP}
      keymode={Astal.Keymode.ON_DEMAND}
      marginTop={6}
      marginRight={6}
      application={app}
      onKeyPressed={(self, keyval) => {
        if (keyval === 65307) {
          const overlay = app.get_window("control-center-overlay")
          self.visible = false
          if (overlay) overlay.visible = false
        }
      }}
    >
      <box
        orientation={Gtk.Orientation.VERTICAL}
        spacing={8}
        css="padding: 16px;"
        widthRequest={400}
      >
        <Header />
        <Network />
        <Audio />
        <Brightness />
        <Bluetooth />
        <PowerProfile />
        <Battery />
        <Media />
      </box>
    </window>
  )
}
