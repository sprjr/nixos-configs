import Gtk from "gi://Gtk?version=4.0"
import AstalBrightness from "gi://AstalBrightness"
import { createBinding } from "ags"

export default function Brightness() {
  let brightness: AstalBrightness.Brightness | null = null
  try {
    brightness = AstalBrightness.get_default()
  } catch {
    return <box visible={false} />
  }

  if (!brightness || brightness.screen < 0) {
    return <box visible={false} />
  }

  return (
    <box class="section" orientation={Gtk.Orientation.VERTICAL} spacing={4}>
      <box class="section-header" spacing={8}>
        <image iconName="display-brightness-symbolic" />
        <label label="Brightness" hexpand xalign={0} class="section-title" />
      </box>
      <box spacing={8}>
        <image iconName="display-brightness-low-symbolic" css="margin-left: 4px;" />
        <slider
          class="brightness-slider"
          hexpand
          value={createBinding(brightness, "screen")}
          onChangeValue={({ value }) => {
            brightness!.screen = value
          }}
        />
        <label
          label={createBinding(brightness, "screen")((v: number) => `${Math.round(v * 100)}%`)}
          widthChars={4}
          xalign={1}
        />
      </box>
    </box>
  )
}
