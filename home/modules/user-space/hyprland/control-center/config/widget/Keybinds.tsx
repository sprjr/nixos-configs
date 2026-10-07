import app from "ags/gtk4/app"
import Astal from "gi://Astal?version=4.0"
import Gtk from "gi://Gtk?version=4.0"
import Gdk from "gi://Gdk?version=4.0"
import { For } from "ags"
import { dismiss } from "./Overlay"
import groups, { type Group } from "../keybind-data"

// Two columns keep the panel inside one screen; the split is by row count.
const half = Math.ceil(groups.length / 2)
const columns = [groups.slice(0, half), groups.slice(half)]

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
        <For each={groups}>
          {(group: Group) => (
            <box class="section" orientation={Gtk.Orientation.VERTICAL} spacing={2}>
              <box class="section-header" spacing={8}>
                <image iconName={group.icon} />
                <label label={group.title} hexpand xalign={0} class="section-title" />
              </box>
              <For each={group.binds}>
                {(bind) => (
                  <box class="kb-row" spacing={8}>
                    <label label={bind.keys} class="kb-keys" xalign={0} widthRequest={104} />
                    <label label={bind.desc} class="kb-desc" hexpand xalign={0} />
                  </box>
                )}
              </For>
            </box>
          )}
        </For>
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
