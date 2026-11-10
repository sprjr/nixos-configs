import app from "ags/gtk4/app"
import Gtk from "gi://Gtk?version=4.0"
import { createState } from "ags"
import { exec, execAsync, subprocess } from "ags/process"
import { timeout } from "ags/time"
import AstalIO from "gi://AstalIO"

let daemon: "hokum" | "swaync" = "swaync"
try { exec("pgrep -x hokum"); daemon = "hokum" } catch {}

const watch = daemon === "hokum"
  ? ["hokum", "dnd", "--json", "--watch"]
  : ["swaync-client", "-s"]
const toggle = daemon === "hokum"
  ? ["hokum", "dnd", "toggle"]
  : ["swaync-client", "-d", "-sw"]

function dismiss() {
  const cc = app.get_window("control-center")
  const overlay = app.get_window("control-center-overlay")
  if (cc) cc.visible = false
  if (overlay) overlay.visible = false
}

function DndToggle() {
  const [dnd, setDnd] = createState(false)

  subprocess(
    watch,
    (line) => {
      try {
        setDnd(!!JSON.parse(line).dnd)
      } catch (e) {
        console.error(e)
      }
    },
    (err) => console.error(err),
  )

  return (
    <button
      class={dnd((on) => (on ? "header-btn active" : "header-btn"))}
      tooltipText={dnd((on) => (on ? "Do Not Disturb: on" : "Do Not Disturb: off"))}
      onClicked={() => execAsync(toggle).catch(console.error)}
    >
      <image
        iconName={dnd((on) =>
          on ? "notifications-disabled-symbolic" : "preferences-system-notifications-symbolic",
        )}
      />
    </button>
  )
}

function LockButton() {
  return (
    <button
      class="header-btn"
      tooltipText="Lock"
      onClicked={() => {
        dismiss()
        execAsync(["hyprlock"]).catch(console.error)
      }}
    >
      <image iconName="system-lock-screen-symbolic" />
    </button>
  )
}

const CONFIRM_MS = 3000

// Two-click guard for destructive actions: the first click arms the button
// (red, tooltip changes), a second click within CONFIRM_MS runs the command.
// Arming one button disarms the others so only one action is ever pending.
const [armed, setArmed] = createState<string | null>(null)
let disarmTimer: AstalIO.Time | null = null

function ConfirmButton({ label, icon, cmd }: { label: string; icon: string; cmd: string[] }) {
  return (
    <button
      class={armed((a) => (a === label ? "header-btn armed" : "header-btn"))}
      tooltipText={armed((a) => (a === label ? `Click again to ${label.toLowerCase()}` : label))}
      onClicked={() => {
        disarmTimer?.cancel()
        if (armed.get() === label) {
          setArmed(null)
          execAsync(cmd).catch(console.error)
        } else {
          setArmed(label)
          disarmTimer = timeout(CONFIRM_MS, () => setArmed(null))
        }
      }}
    >
      <image iconName={icon} />
    </button>
  )
}

export default function Header() {
  return (
    <box class="section header" spacing={4}>
      <DndToggle />
      <box hexpand />
      <LockButton />
      <ConfirmButton label="Logout" icon="system-log-out-symbolic" cmd={["hyprctl", "dispatch", "exit"]} />
      <ConfirmButton label="Reboot" icon="system-reboot-symbolic" cmd={["systemctl", "reboot"]} />
      <ConfirmButton label="Shutdown" icon="system-shutdown-symbolic" cmd={["systemctl", "poweroff"]} />
    </box>
  )
}
