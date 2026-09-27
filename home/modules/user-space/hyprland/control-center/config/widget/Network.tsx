import Gtk from "gi://Gtk?version=4.0"
import AstalNetwork from "gi://AstalNetwork"
import { For, With, createBinding } from "ags"
import { execAsync } from "ags/process"

function AccessPointRow({ ap, wifi }: { ap: AstalNetwork.AccessPoint; wifi: AstalNetwork.Wifi }) {
  const isActive = createBinding(wifi, "activeAccessPoint")((active) => active === ap)

  return (
    <button
      class="ap-row"
      onClicked={() => {
        execAsync(["nmcli", "d", "wifi", "connect", ap.bssid]).catch(console.error)
      }}
    >
      <box spacing={8}>
        <image iconName={createBinding(ap, "iconName")} />
        <label label={createBinding(ap, "ssid")} hexpand xalign={0} />
        <image iconName="object-select-symbolic" visible={isActive} />
      </box>
    </button>
  )
}

export default function Network() {
  const network = AstalNetwork.get_default()
  const wifi = createBinding(network, "wifi")

  const sortedAps = (aps: AstalNetwork.AccessPoint[]) =>
    aps.filter((ap) => !!ap.ssid).sort((a, b) => b.strength - a.strength)

  return (
    <box class="section" orientation={Gtk.Orientation.VERTICAL} spacing={4} visible={wifi(Boolean)}>
      <With value={wifi}>
        {(wifi) =>
          wifi && (
            <box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
              <box class="section-header" spacing={8}>
                <image iconName={createBinding(wifi, "iconName")} />
                <label label="Wi-Fi" hexpand xalign={0} class="section-title" />
                <switch
                  active={createBinding(wifi, "enabled")}
                  onActivate={({ active }) => {
                    execAsync(["nmcli", "radio", "wifi", active ? "on" : "off"])
                  }}
                />
              </box>
              <box
                class="ap-list"
                orientation={Gtk.Orientation.VERTICAL}
                spacing={2}
                visible={createBinding(wifi, "enabled")}
              >
                <For each={createBinding(wifi, "accessPoints")(sortedAps)}>
                  {(ap: AstalNetwork.AccessPoint) => <AccessPointRow ap={ap} wifi={wifi} />}
                </For>
              </box>
            </box>
          )
        }
      </With>
    </box>
  )
}
