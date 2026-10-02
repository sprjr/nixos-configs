import app from "ags/gtk4/app"
import Gtk from "gi://Gtk?version=4.0"
import { createState } from "ags"
import { execAsync, subprocess } from "ags/process"

function dismiss() {
  const cc = app.get_window("control-center")
  const overlay = app.get_window("control-center-overlay")
  if (cc) cc.visible = false
  if (overlay) overlay.visible = false
}

function DndToggle() {
  const [dnd, setDnd] = createState(false)

  // swaync-client -s streams {"count", "dnd", "visible", "inhibited"} on every change,
  // so DND toggled from waybar or swaync's own panel is reflected here too
  subprocess(
    ["swaync-client", "-s"],
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
      onClicked={() => execAsync(["swaync-client", "-d", "-sw"]).catch(console.error)}
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

function LogoutButton() {
  return (
    <button
      class="header-btn"
      tooltipText="Logout"
      onClicked={() => execAsync(["hyprctl", "dispatch", "exit"]).catch(console.error)}
    >
      <image iconName="system-log-out-symbolic" />
    </button>
  )
}

function RebootButton() {
  return (
    <button
      class="header-btn"
      tooltipText="Reboot"
      onClicked={() => execAsync(["systemctl", "reboot"]).catch(console.error)}
    >
      <image iconName="system-reboot-symbolic" />
    </button>
  )
}

function ShutdownButton() {
  return (
    <button
      class="header-btn"
      tooltipText="Shutdown"
      onClicked={() => execAsync(["systemctl", "poweroff"]).catch(console.error)}
    >
      <image iconName="system-shutdown-symbolic" />
    </button>
  )
}

export default function Header() {
  return (
    <box class="section header" spacing={4}>
      <DndToggle />
      <box hexpand />
      <LockButton />
      <LogoutButton />
      <RebootButton />
      <ShutdownButton />
    </box>
  )
}
