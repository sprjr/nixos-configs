import app from "ags/gtk4/app"
import Astal from "gi://Astal?version=4.0"
import Gtk from "gi://Gtk?version=4.0"
import Gdk from "gi://Gdk?version=4.0"
import { dismiss } from "./Overlay"
import groups, { type Group } from "../keybind-data"

// Two columns keep the panel inside one screen; the split is by row count.
// A group's height is its rows plus the header; pick the cut closest to half.
const height = (g: Group) => g.binds.length + 1
const total = groups.reduce((n, g) => n + height(g), 0)
let split = 0
let best = total
let acc = 0
groups.forEach((g, i) => {
  acc += height(g)
  const diff = Math.abs(total - 2 * acc)
  if (diff < best) {
    best = diff
    split = i + 1
  }
})
const columns = [groups.slice(0, split), groups.slice(split)]

function Column({ groups }: { groups: Group[] }) {
  return (
    <scrolledwindow
      widthRequest={320}
      maxContentHeight={820}
      propagateNaturalHeight
      hscrollbarPolicy={Gtk.PolicyType.NEVER}
      vscrollbarPolicy={Gtk.PolicyType.AUTOMATIC}
    >
      <box class="kb-column" orientation={Gtk.Orientation.VERTICAL} spacing={8}>
        {groups.map((group) => (
          <box class="section" orientation={Gtk.Orientation.VERTICAL} spacing={2}>
            <box class="section-header" spacing={8}>
              <image iconName={group.icon} />
              <label label={group.title} hexpand xalign={0} class="section-title" />
            </box>
            {group.binds.map((bind) => (
              <box class="kb-row" spacing={8}>
                <label label={bind.keys} class="kb-keys" xalign={0} widthRequest={104} />
                <label label={bind.desc} class="kb-desc" hexpand xalign={0} />
              </box>
            ))}
          </box>
        ))}
      </box>
    </scrolledwindow>
  )
}

export default function Keybinds() {
  const { TOP, RIGHT } = Astal.WindowAnchor

  return (
    <window
      visible={false}
      name="keybinds"
      namespace="keybinds"
      anchor={TOP | RIGHT}
      layer={Astal.Layer.TOP}
      keymode={Astal.Keymode.ON_DEMAND}
      marginTop={6}
      marginRight={6}
      application={app}
    >
      <Gtk.EventControllerKey
        onKeyPressed={(_, keyval) => {
          if (keyval === Gdk.KEY_Escape) dismiss()
          return false
        }}
      />
      <box orientation={Gtk.Orientation.HORIZONTAL} spacing={8} css="padding: 16px;">
        <Column groups={columns[0]} />
        <Column groups={columns[1]} />
      </box>
    </window>
  )
}
