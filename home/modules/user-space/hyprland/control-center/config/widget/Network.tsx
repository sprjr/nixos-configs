import Gtk from "gi://Gtk?version=4.0"
import AstalNetwork from "gi://AstalNetwork"
import { For, With, createBinding, createState } from "ags"
import { execAsync } from "ags/process"
import ExpandButton from "./ExpandButton"

// Connection attempt in flight or awaiting a password; one at a time
type Attempt = {
  ssid: string
  prompt: boolean
  error: boolean
  message: string
}

function AccessPointRow({
  ap,
  wifi,
  onSelect,
}: {
  ap: AstalNetwork.AccessPoint
  wifi: AstalNetwork.Wifi
  onSelect: (ap: AstalNetwork.AccessPoint) => void
}) {
  // Compared by SSID so the checkmark survives roaming between BSSIDs
  const isActive = createBinding(wifi, "activeAccessPoint")((active) => active?.ssid === ap.ssid)

  return (
    <button class="ap-row" onClicked={() => onSelect(ap)}>
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
  const [attempt, setAttempt] = createState<Attempt | null>(null)

  let entry: Gtk.PasswordEntry | null = null

  // Strongest AP per SSID, strongest first
  const sortedAps = (aps: AstalNetwork.AccessPoint[]) => {
    const best = new Map<string, AstalNetwork.AccessPoint>()
    for (const ap of aps) {
      if (!ap.ssid) continue
      const current = best.get(ap.ssid)
      if (!current || ap.strength > current.strength) best.set(ap.ssid, ap)
    }
    return [...best.values()].sort((a, b) => b.strength - a.strength)
  }

  const connect = (ssid: string, secured: boolean, password?: string) => {
    setAttempt({ ssid, prompt: false, error: false, message: `Connecting to ${ssid}…` })

    const args = ["nmcli", "device", "wifi", "connect", ssid]
    if (password !== undefined) args.push("password", password)

    execAsync(args)
      .then(() => {
        if (attempt.get()?.ssid === ssid) setAttempt(null)
      })
      .catch((e) => {
        // A newer attempt on another network owns the state
        if (attempt.get()?.ssid !== ssid) return
        const message = String(e).trim()

        // No saved profile for a secured network: ask for the password
        if (password === undefined && (secured || message.includes("Secrets were required"))) {
          setAttempt({ ssid, prompt: true, error: false, message: `Password for ${ssid}` })
          entry?.grab_focus()
          return
        }
        setAttempt({ ssid, prompt: password !== undefined, error: true, message })
      })
  }

  const select = (ap: AstalNetwork.AccessPoint, active: AstalNetwork.AccessPoint | null) => {
    if (active?.ssid === ap.ssid) return
    entry?.set_text("")
    connect(ap.ssid, ap.rsnFlags !== 0 || ap.wpaFlags !== 0)
  }

  const submit = () => {
    const current = attempt.get()
    const password = entry?.get_text() ?? ""
    if (!current?.prompt || !password) return
    entry?.set_text("")
    connect(current.ssid, true, password)
  }

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
                <box
                  orientation={Gtk.Orientation.VERTICAL}
                  spacing={4}
                  visible={createBinding(wifi, "enabled")}
                >
                  <label
                    class={attempt((a) => (a?.error ? "ap-status error" : "ap-status"))}
                    label={attempt((a) => a?.message ?? "")}
                    visible={attempt((a) => a !== null)}
                    xalign={0}
                    wrap
                  />
                  <box class="ap-password" spacing={8} visible={attempt((a) => a?.prompt ?? false)}>
                    <Gtk.PasswordEntry
                      $={(self) => (entry = self)}
                      hexpand
                      showPeekIcon
                      onActivate={submit}
                    />
                    <button class="ap-connect" label="Connect" onClicked={submit} />
                    <button class="expand-btn" onClicked={() => setAttempt(null)}>
                      <image iconName="window-close-symbolic" />
                    </button>
                  </box>
                  <scrolledwindow
                    hscrollbarPolicy={Gtk.PolicyType.NEVER}
                    propagateNaturalHeight
                    maxContentHeight={200}
                  >
                    <box class="ap-list" orientation={Gtk.Orientation.VERTICAL} spacing={2}>
                      <For each={createBinding(wifi, "accessPoints")(sortedAps)}>
                        {(ap: AstalNetwork.AccessPoint) => (
                          <AccessPointRow
                            ap={ap}
                            wifi={wifi}
                            onSelect={(ap) => select(ap, wifi.activeAccessPoint)}
                          />
                        )}
                      </For>
                    </box>
                  </scrolledwindow>
                </box>
              </revealer>
            </box>
          )
        }
      </With>
    </box>
  )
}
