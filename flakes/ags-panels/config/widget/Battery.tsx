import Gtk from "gi://Gtk?version=4.0"
import AstalBattery from "gi://AstalBattery"
import { createBinding } from "ags"

export default function Battery() {
  const battery = AstalBattery.get_default()
  const isPresent = createBinding(battery, "isPresent")

  const percent = createBinding(battery, "percentage")((p: number) =>
    `${Math.floor(p * 100)}%`
  )

  const timeLabel = createBinding(battery, "timeToEmpty")((seconds: number) => {
    if (seconds <= 0) return ""
    const h = Math.floor(seconds / 3600)
    const m = Math.floor((seconds % 3600) / 60)
    return h > 0 ? `${h}h ${m}m remaining` : `${m}m remaining`
  })

  const chargingLabel = createBinding(battery, "charging")((charging: boolean) =>
    charging ? "Charging" : "On Battery"
  )

  return (
    <box class="section" orientation={Gtk.Orientation.VERTICAL} spacing={4} visible={isPresent}>
      <box class="section-header" spacing={8}>
        <image iconName={createBinding(battery, "iconName")} />
        <label label="Battery" hexpand xalign={0} class="section-title" />
        <label label={percent} class="battery-percent" />
      </box>
      <box spacing={8} css="margin-left: 4px;">
        <label label={chargingLabel} class="battery-status" />
        <label label={timeLabel} class="battery-time" hexpand xalign={1} />
      </box>
      <levelbar
        class="battery-bar"
        value={createBinding(battery, "percentage")}
        minValue={0}
        maxValue={1}
      />
    </box>
  )
}
