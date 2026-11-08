import Gtk from "gi://Gtk?version=4.0"
import GLib from "gi://GLib"

function run(cmd: string): string | null {
  try {
    const [, out] = GLib.spawn_command_line_sync(cmd)
    if (!out) return null
    return new TextDecoder().decode(out).trim()
  } catch {
    return null
  }
}

function getBrightness(): number {
  const cur = run("brightnessctl get")
  const max = run("brightnessctl max")
  if (!cur || !max) return -1
  return parseInt(cur) / parseInt(max)
}

export default function Brightness() {
  const initial = getBrightness()
  if (initial < 0) return <box visible={false} />

  const pctLabel = new Gtk.Label({
    label: `${Math.round(initial * 100)}%`,
    widthChars: 4,
    xalign: 1,
  })

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
          value={initial}
          onChangeValue={(self: { value: number }) => {
            const pct = Math.round(self.value * 100)
            pctLabel.label = `${pct}%`
            GLib.spawn_command_line_async(`brightnessctl set ${pct}%`)
          }}
        />
        {pctLabel}
      </box>
    </box>
  )
}
