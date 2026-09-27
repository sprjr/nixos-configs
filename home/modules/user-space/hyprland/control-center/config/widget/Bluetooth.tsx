import Gtk from "gi://Gtk?version=4.0"
import AstalBluetooth from "gi://AstalBluetooth"
import { For, createBinding } from "ags"

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
          onActivate={({ active }) => {
            adapter.powered = active
          }}
        />
      </box>
      <box
        class="bt-device-list"
        orientation={Gtk.Orientation.VERTICAL}
        spacing={2}
        visible={isPowered}
      >
        <For each={pairedDevices}>
          {(device: AstalBluetooth.Device) => <DeviceRow device={device} />}
        </For>
      </box>
    </box>
  )
}
