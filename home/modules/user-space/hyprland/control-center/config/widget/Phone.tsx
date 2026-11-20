import app from "ags/gtk4/app"
import Astal from "gi://Astal?version=4.0"
import Gtk from "gi://Gtk?version=4.0"
import Gdk from "gi://Gdk?version=4.0"
import Gio from "gi://Gio"
import AstalIO from "gi://AstalIO"
import { For, createState } from "ags"
import { execAsync } from "ags/process"
import { interval, timeout } from "ags/time"
import { dismiss } from "./Overlay"

const DEST = "org.kde.kdeconnect"
const ROOT = "/modules/kdeconnect"
const DEV = "org.kde.kdeconnect.device"
const POLL_MS = 5000

type Notif = { id: string; app: string; title: string; text: string; dismissable: boolean }

// Output of `kdeconnect-status --panel` (widgets/kdeconnect.nix)
type Phone = {
  id: string
  name: string
  reachable: boolean
  charge: number | null
  charging: boolean
  netType: string
  netStrength: number | null
  notifs: Notif[]
}

const SIGNAL_ICONS = ["none", "weak", "ok", "good", "excellent"].map((s) => `network-cellular-signal-${s}-symbolic`)

// Fire-and-forget D-Bus method for actions (sftp browse, notification dismiss)
function callAsync(path: string, iface: string, method: string): Promise<void> {
  return new Promise((resolve, reject) =>
    Gio.DBus.session.call(DEST, path, iface, method, null, null, Gio.DBusCallFlags.NO_AUTO_START, -1, null, (conn, res) => {
      try {
        conn!.call_finish(res)
        resolve()
      } catch (e) {
        reject(e)
      }
    }),
  )
}

function status(p: Phone | null) {
  if (!p) return "No paired device"
  return p.reachable ? "Connected" : "Not reachable"
}

function batteryIcon(p: Phone | null) {
  if (p?.charge == null) return "battery-missing-symbolic"
  const level = Math.round(p.charge / 10) * 10
  return `battery-level-${level}${p.charging ? "-charging" : ""}-symbolic`
}

function batteryLevel(c: number | null) {
  if (c == null) return ""
  if (c <= 15) return "critical"
  return c <= 30 ? "warning" : ""
}

export default function PhonePanel() {
  const { TOP, RIGHT } = Astal.WindowAnchor
  const [phone, setPhone] = createState<Phone | null>(null)
  const [note, setNote] = createState("")

  const refresh = () =>
    execAsync(["kdeconnect-status", "--panel"])
      .then((out) => setPhone(JSON.parse(out)))
      .catch((e) => {
        console.error(e)
        setPhone(null)
      })

  const flash = (msg: string) => {
    setNote(msg)
    timeout(3000, () => setNote(""))
  }

  const cli = (...args: string[]) => {
    const p = phone.get()
    return p ? execAsync(["kdeconnect-cli", "-d", p.id, ...args]) : Promise.reject("no device")
  }

  const devPath = () => `${ROOT}/devices/${phone.get()?.id}`

  // Native file chooser; panel closes first so it doesn't cover the dialog
  function shareFiles() {
    dismiss()
    new Gtk.FileDialog({ title: "Share to phone" }).open_multiple(null, null, (dialog, res) => {
      try {
        const files = dialog!.open_multiple_finish(res)
        for (let i = 0; i < files.get_n_items(); i++) {
          const path = (files.get_item(i) as Gio.File).get_path()
          if (path) cli("--share", path).catch(console.error)
        }
      } catch {}
    })
  }

  const actions: { icon: string; label: string; run: () => Promise<unknown>; done?: string; close?: boolean }[] = [
    { icon: "audio-volume-high-symbolic", label: "Ring", run: () => cli("--ring"), done: "Ringing" },
    { icon: "mail-send-symbolic", label: "Ping", run: () => cli("--ping"), done: "Ping sent" },
    { icon: "edit-paste-symbolic", label: "Clipboard", run: () => cli("--send-clipboard"), done: "Clipboard sent" },
    { icon: "document-send-symbolic", label: "Share file", run: async () => shareFiles() },
    {
      icon: "folder-remote-symbolic",
      label: "Browse",
      run: () => callAsync(`${devPath()}/sftp`, `${DEV}.sftp`, "startBrowsing"),
      close: true,
    },
    { icon: "mail-message-new-symbolic", label: "SMS", run: () => execAsync(["kdeconnect-sms"]), close: true },
  ]

  const runAction = (a: (typeof actions)[number]) => {
    if (a.close) dismiss()
    a.run()
      .then(() => a.done && flash(a.done))
      .catch((e) => flash(`${a.label} failed: ${e}`))
  }

  const dismissNotif = (n: Notif) =>
    callAsync(`${devPath()}/notifications/${n.id}`, `${DEV}.notifications.notification`, "dismiss")
      .catch((e) => flash(`Dismiss failed: ${e}`))
      .finally(refresh)

  let timer: AstalIO.Time | null = null

  function start() {
    if (timer) return
    refresh()
    timer = interval(POLL_MS, refresh)
  }

  function stop() {
    timer?.cancel()
    timer = null
  }

  const reachable = phone((p) => !!p?.reachable)

  return (
    <window
      visible={false}
      name="phone"
      namespace="phone"
      anchor={TOP | RIGHT}
      layer={Astal.Layer.TOP}
      keymode={Astal.Keymode.ON_DEMAND}
      marginTop={6}
      marginRight={6}
      application={app}
      onNotifyVisible={(self) => (self.visible ? start() : stop())}
    >
      <Gtk.EventControllerKey
        onKeyPressed={(_, keyval) => {
          if (keyval === Gdk.KEY_Escape) dismiss()
          return false
        }}
      />
      <box orientation={Gtk.Orientation.VERTICAL} spacing={8} css="padding: 16px;" widthRequest={400}>
        <box class="section" spacing={8}>
          <image iconName="phone-symbolic" class={reachable((r) => (r ? "phone-icon online" : "phone-icon"))} />
          <box orientation={Gtk.Orientation.VERTICAL} hexpand>
            <label label={phone((p) => p?.name ?? "KDE Connect")} class="section-title" xalign={0} ellipsize={3} />
            <label label={phone(status)} class={reachable((r) => (r ? "phone-status" : "phone-status offline"))} xalign={0} />
          </box>
          <button
            class="header-btn"
            tooltipText="Refresh / rediscover"
            onClicked={() => execAsync(["kdeconnect-cli", "--refresh"]).catch(console.error).finally(refresh)}
          >
            <image iconName="view-refresh-symbolic" />
          </button>
          <button
            class="header-btn"
            tooltipText="KDE Connect settings"
            onClicked={() => {
              dismiss()
              execAsync(["kdeconnect-app"]).catch(console.error)
            }}
          >
            <image iconName="emblem-system-symbolic" />
          </button>
        </box>

        <box class="section" orientation={Gtk.Orientation.VERTICAL} spacing={4} visible={phone((p) => p?.charge != null)}>
          <box class="section-header" spacing={8}>
            <image iconName={phone(batteryIcon)} />
            <label label="Battery" hexpand xalign={0} class="section-title" />
            <label label={phone((p) => `${p?.charge ?? "--"}%`)} class="battery-percent" />
          </box>
          <levelbar
            class={phone((p) => `battery-bar phone-battery ${batteryLevel(p?.charge ?? null)}`)}
            minValue={0}
            maxValue={100}
            value={phone((p) => p?.charge ?? 0)}
          />
          <label
            label={phone((p) => (p?.charging ? "Charging" : "Discharging") + (p?.reachable ? "" : " · last known"))}
            class="battery-status"
            xalign={0}
          />
        </box>

        <box
          class="section"
          spacing={8}
          visible={phone((p) => !!p?.reachable && (p.netType !== "" || p.netStrength != null))}
        >
          <image iconName={phone((p) => SIGNAL_ICONS[p?.netStrength ?? 0])} />
          <label label="Cellular" hexpand xalign={0} class="section-title" />
          <label
            label={phone((p) =>
              [p?.netType, p?.netStrength != null ? `${p.netStrength}/4` : ""].filter(Boolean).join(" · "),
            )}
            class="hw-stat"
          />
        </box>

        <box class="section" orientation={Gtk.Orientation.VERTICAL} spacing={4} visible={phone((p) => p != null)}>
          {[actions.slice(0, 3), actions.slice(3)].map((row) => (
            <box spacing={4} homogeneous>
              {row.map((a) => (
                <button class="profile-btn" sensitive={reachable} onClicked={() => runAction(a)}>
                  <box orientation={Gtk.Orientation.VERTICAL} spacing={2}>
                    <image iconName={a.icon} />
                    <label label={a.label} />
                  </box>
                </button>
              ))}
            </box>
          ))}
          <label label={note} class="ap-status" visible={note((n) => n !== "")} xalign={0} wrap />
        </box>

        <box
          class="section"
          orientation={Gtk.Orientation.VERTICAL}
          spacing={4}
          visible={phone((p) => !!p?.reachable && p.notifs.length > 0)}
        >
          <box class="section-header" spacing={8}>
            <image iconName="preferences-system-notifications-symbolic" />
            <label label="Notifications" hexpand xalign={0} class="section-title" />
            <label label={phone((p) => String(p?.notifs.length ?? 0))} class="hw-stat" />
          </box>
          <scrolledwindow
            maxContentHeight={320}
            propagateNaturalHeight
            hscrollbarPolicy={Gtk.PolicyType.NEVER}
            vscrollbarPolicy={Gtk.PolicyType.AUTOMATIC}
          >
            <box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
              <For each={phone((p) => p?.notifs ?? [])}>
                {(n: Notif) => (
                  <box class="phone-notif" spacing={8} tooltipText={n.text}>
                    <box orientation={Gtk.Orientation.VERTICAL} hexpand>
                      <label label={n.app} class="hw-sub" xalign={0} ellipsize={3} />
                      <label label={n.title} class="media-title" xalign={0} ellipsize={3} />
                      <label label={n.text} class="media-artist" xalign={0} ellipsize={3} />
                    </box>
                    <button
                      class="mute-btn"
                      valign={Gtk.Align.START}
                      visible={n.dismissable}
                      tooltipText="Dismiss on phone"
                      onClicked={() => dismissNotif(n)}
                    >
                      <image iconName="window-close-symbolic" />
                    </button>
                  </box>
                )}
              </For>
            </box>
          </scrolledwindow>
        </box>
      </box>
    </window>
  )
}
