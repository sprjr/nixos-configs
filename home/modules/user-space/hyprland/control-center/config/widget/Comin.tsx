import GLib from "gi://GLib"
import AstalIO from "gi://AstalIO"
import { createState } from "ags"
import type { Accessor } from "ags"
import { readFile } from "ags/file"
import { execAsync } from "ags/process"
import { interval } from "ags/time"

// Output of widgets/comin-state.py
type CominState = {
  state: "in-sync" | "pending" | "in-progress" | "failed" | "unknown"
  label: string
  commit: string
  time: number | null
  detail: string
}

const POLL_MS = 5000

function cominEnabled() {
  try {
    const path = GLib.get_user_config_dir() + "/ags/features.json"
    return JSON.parse(readFile(path)).comin === true
  } catch {
    return false
  }
}

function ago(epoch: number | null) {
  if (epoch == null) return ""
  const s = Math.max(0, Math.floor(Date.now() / 1000) - epoch)
  if (s < 60) return `${s}s ago`
  if (s < 3600) return `${Math.floor(s / 60)}m ago`
  if (s < 86400) return `${Math.floor(s / 3600)}h ago`
  return `${Math.floor(s / 86400)}d ago`
}

// Read-only comin deployment state; polls only while the control center is shown.
export default function Comin({ shown }: { shown: Accessor<boolean> }) {
  if (!cominEnabled()) return <box visible={false} />

  const [status, setStatus] = createState<CominState>({
    state: "unknown",
    label: "Checking…",
    commit: "",
    time: null,
    detail: "",
  })

  const refresh = () =>
    execAsync(["comin-state"])
      .then((out) => setStatus(JSON.parse(out)))
      .catch((e) =>
        setStatus({ state: "unknown", label: "Unknown", commit: "", time: null, detail: String(e) }),
      )

  let timer: AstalIO.Time | null = null
  shown.subscribe(() => {
    if (shown.get()) {
      refresh()
      timer ??= interval(POLL_MS, refresh)
    } else {
      timer?.cancel()
      timer = null
    }
  })

  return (
    <box class="section comin-row" spacing={8} tooltipText={status((s) => s.detail)}>
      <image
        iconName="media-record-symbolic"
        class={status((s) => `comin-dot ${s.state}`)}
      />
      <label label="Comin" class="section-title" />
      <label label={status((s) => s.label)} hexpand xalign={0} />
      <label
        class="comin-meta"
        label={status((s) => [s.commit, ago(s.time)].filter(Boolean).join(" · "))}
      />
    </box>
  )
}
