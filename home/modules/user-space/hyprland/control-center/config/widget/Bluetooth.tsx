import Gtk from "gi://Gtk?version=4.0"
import AstalBluetooth from "gi://AstalBluetooth"
import { For, createBinding, createState } from "ags"
import ExpandButton from "./ExpandButton"

function DeviceRow({ device }: { device: AstalBluetooth.Device }) {
  const connected = createBinding(device, "connected")

  return (
    <button
      class="bt-device-row"
      onClicked={() => {
        if (device.connected) {
          device.disconnect_device(null)
        } else {
          device.connect_device(null)
        }
      }}
    >
      <box spacing={8}>
        <image iconName={createBinding(device, "icon") ?? "bluetooth-symbolic"} />
        <label label={createBinding(device, "name")} hexpand xalign={0} />
        <image iconName="object-select-symbolic" visible={connected} />
      </box>
    </button>
  )
}

export default function Bluetooth() {
  const bt = AstalBluetooth.get_default()
  const adapter = bt.adapter
  const isPowered = createBinding(adapter, "powered")
  const devices = createBinding(bt, "devices")

  const [expanded, setExpanded] = createState(false)

  const pairedDevices = devices((devs: AstalBluetooth.Device[]) =>
    devs.filter((d) => d.paired)
  )

  return (
    <box class="section" orientation={Gtk.Orientation.VERTICAL} spacing={4}>
      <box class="section-header" spacing={8}>
        <image iconName="bluetooth-active-symbolic" />
        <label label="Bluetooth" hexpand xalign={0} class="section-title" />
        <switch
          active={isPowered}
          onNotifyActive={({ active }) => {
            if (adapter.powered !== active) adapter.powered = active
          }}
        />
        <ExpandButton expanded={expanded} setExpanded={setExpanded} />
      </box>
      <revealer revealChild={expanded}>
        <scrolledwindow
          hscrollbarPolicy={Gtk.PolicyType.NEVER}
          propagateNaturalHeight
          maxContentHeight={200}
          visible={isPowered}
        >
          <box class="bt-device-list" orientation={Gtk.Orientation.VERTICAL} spacing={2}>
            <For each={pairedDevices}>
              {(device: AstalBluetooth.Device) => <DeviceRow device={device} />}
            </For>
          </box>
        </scrolledwindow>
      </revealer>
    </box>
  )
}
