import Gtk from "gi://Gtk?version=4.0"
import AstalNetwork from "gi://AstalNetwork"
import { For, With, createBinding, createState } from "ags"
import { execAsync } from "ags/process"
import ExpandButton from "./ExpandButton"

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

  const [expanded, setExpanded] = createState(false)

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
                  onNotifyActive={({ active }) => {
                    if (wifi.enabled !== active) wifi.enabled = active
                  }}
                />
                <ExpandButton expanded={expanded} setExpanded={setExpanded} />
              </box>
              <revealer revealChild={expanded}>
                <scrolledwindow
                  hscrollbarPolicy={Gtk.PolicyType.NEVER}
                  propagateNaturalHeight
                  maxContentHeight={200}
                  visible={createBinding(wifi, "enabled")}
                >
                  <box class="ap-list" orientation={Gtk.Orientation.VERTICAL} spacing={2}>
                    <For each={createBinding(wifi, "accessPoints")(sortedAps)}>
                      {(ap: AstalNetwork.AccessPoint) => <AccessPointRow ap={ap} wifi={wifi} />}
                    </For>
                  </box>
                </scrolledwindow>
              </revealer>
            </box>
          )
        }
      </With>
    </box>
  )
}
