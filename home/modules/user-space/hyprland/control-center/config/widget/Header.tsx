import app from "ags/gtk4/app"
import Gtk from "gi://Gtk?version=4.0"
import { execAsync } from "ags/process"

function dismiss() {
  const cc = app.get_window("control-center")
  const overlay = app.get_window("control-center-overlay")
  if (cc) cc.visible = false
  if (overlay) overlay.visible = false
}

function DndToggle() {
  return (
    <button
      class="header-btn"
      tooltipText="Do Not Disturb"
      onClicked={() => execAsync(["swaync-client", "-d", "-sw"]).catch(console.error)}
    >
      <image iconName="notifications-disabled-symbolic" />
    </button>
  )
}

function IdleInhibit() {
  return (
    <button
      class="header-btn"
      tooltipText="Toggle hypridle"
      onClicked={() =>
        execAsync([
          "sh",
          "-c",
          "if systemctl --user is-active --quiet hypridle; then systemctl --user stop hypridle; else systemctl --user start hypridle; fi",
        ]).catch(console.error)
      }
    >
      <image iconName="caffeine-cup-empty-symbolic" />
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
      <IdleInhibit />
      <box hexpand />
      <LockButton />
      <LogoutButton />
      <RebootButton />
      <ShutdownButton />
    </box>
  )
}
