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
      onClicked={() => execAsync(["swaync-client", "-d", "-sw"])}
    >
      <image iconName="notifications-disabled-symbolic" />
    </button>
  )
}

function IdleInhibit() {
  return (
    <button
      class="header-btn"
      tooltipText="Idle Inhibitor"
      onClicked={() => execAsync(["sh", "-c", "pidof wayland-idle-inhibitor.py && pkill wayland-idle-inhibitor.py || wayland-idle-inhibitor.py"])}
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
        execAsync(["hyprlock"])
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
      onClicked={() => execAsync(["hyprctl", "dispatch", "exit"])}
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
      onClicked={() => execAsync(["systemctl", "reboot"])}
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
      onClicked={() => execAsync(["systemctl", "poweroff"])}
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
