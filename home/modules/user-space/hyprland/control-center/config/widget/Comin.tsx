import GLib from "gi://GLib"
import Gtk from "gi://Gtk?version=4.0"
import AstalIO from "gi://AstalIO"
import { For, createState } from "ags"
import type { Accessor } from "ags"
import { readFile } from "ags/file"
import { execAsync } from "ags/process"
import { interval } from "ags/time"

type Phase = "eval" | "build" | "switch"

// Output of widgets/comin-state.py
type CominState = {
  state: "in-sync" | "pending" | "in-progress" | "failed" | "unknown"
  label: string
  commit: string
  time: number | null
  detail: string
  phase: Phase | null
}

type FleetHost = {
  host: string
  state: "in-sync" | "failed" | "pending" | "offline"
  commit: string
}

// Output of widgets/comin-fleet.py
type FleetState = {
  ok: boolean
  total: number
  hosts: FleetHost[]
  detail: string
}

const POLL_MS = 5000
// Fleet data is already up to ~75s old (exporter timer + scrape interval)
const FLEET_POLL_MS = 30000

const STEPS: { phase: Phase; label: string }[] = [
  { phase: "eval", label: "Evaluating" },
  { phase: "build", label: "Building" },
  { phase: "switch", label: "Switching" },
]

const FLEET_LABELS = { "in-sync": "In sync", failed: "Failed", pending: "Pending", offline: "Offline" }

function cominEnabled() {
  try {
    const path = GLib.get_user_config_dir() + "/ags/features.json"
    return JSON.parse(readFile(path)).comin === true
  } catch {
    return false
  }
}

function since(epoch: number) {
  return Math.max(0, Math.floor(Date.now() / 1000) - epoch)
}

function ago(epoch: number | null) {
  if (epoch == null) return ""
  const s = since(epoch)
  if (s < 60) return `${s}s ago`
  if (s < 3600) return `${Math.floor(s / 60)}m ago`
  if (s < 86400) return `${Math.floor(s / 3600)}h ago`
  return `${Math.floor(s / 86400)}d ago`
}

function elapsed(epoch: number | null) {
  if (epoch == null) return ""
  const s = since(epoch)
  return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`
}

function meta(s: CominState) {
  const time = s.state === "in-progress" ? elapsed(s.time) : ago(s.time)
  return [s.commit, time].filter(Boolean).join(" · ")
}

function stepClass(current: Phase | null, index: number) {
  const at = STEPS.findIndex((s) => s.phase === current)
  if (index < at) return "done"
  return index === at ? "active" : "todo"
}

function fleetStatus(f: FleetState | null) {
  if (!f) return "Checking fleet…"
  return f.ok ? "" : "Fleet unreachable"
}

// Two hosts per column, so the grid stays two rows tall and grows sideways
function columns(hosts: FleetHost[]) {
  const cols: FleetHost[][] = []
  for (let i = 0; i < hosts.length; i += 2) cols.push(hosts.slice(i, i + 2))
  return cols
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
    phase: null,
  })
  // Kept apart from status so the running clock can tick between polls
  const [metaText, setMetaText] = createState("")
  const [fleet, setFleet] = createState<FleetState | null>(null)

  const update = (s: CominState) => {
    setStatus(s)
    setMetaText(meta(s))
  }

  const refresh = () =>
    execAsync(["comin-state"])
      .then((out) => update(JSON.parse(out)))
      .catch((e) =>
        update({ state: "unknown", label: "Unknown", commit: "", time: null, detail: String(e), phase: null }),
      )

  const refreshFleet = () =>
    execAsync(["comin-fleet"])
      .then((out) => setFleet(JSON.parse(out)))
      .catch((e) => setFleet({ ok: false, total: 0, hosts: [], detail: String(e) }))

  let timers: AstalIO.Time[] = []
  shown.subscribe(() => {
    if (shown.get()) {
      if (timers.length > 0) return
      refresh()
      refreshFleet()
      timers = [
        interval(POLL_MS, refresh),
        interval(FLEET_POLL_MS, refreshFleet),
        interval(1000, () => setMetaText(meta(status.get()))),
      ]
    } else {
      timers.forEach((t) => t.cancel())
      timers = []
    }
  })

  return (
    <box class="section comin" orientation={Gtk.Orientation.VERTICAL} spacing={4}>
      <box spacing={8} tooltipText={status((s) => s.detail)}>
        <image
          iconName="media-record-symbolic"
          class={status((s) => `comin-dot ${s.state}`)}
        />
        <label label="Comin" class="section-title" />
        <label label={status((s) => s.label)} hexpand xalign={0} />
        <label class="comin-meta" label={metaText} />
      </box>
      <box class="comin-steps" spacing={8} visible={status((s) => s.phase != null)}>
        {STEPS.map((step, i) => (
          <label label={step.label} class={status((s) => stepClass(s.phase, i))} />
        ))}
      </box>
      <label
        class="comin-fleet"
        label={fleet(fleetStatus)}
        visible={fleet((f) => fleetStatus(f) !== "")}
        tooltipText={fleet((f) => f?.detail ?? "")}
        xalign={0}
      />
      <box class="comin-fleet" spacing={12} homogeneous>
        <For each={fleet((f) => columns(f?.hosts ?? []))}>
          {(col: FleetHost[]) => (
            <box orientation={Gtk.Orientation.VERTICAL} spacing={2}>
              {col.map((h) => (
                <box spacing={4} tooltipText={[FLEET_LABELS[h.state], h.commit].filter(Boolean).join(" · ")}>
                  <image iconName="media-record-symbolic" class={`comin-dot ${h.state}`} />
                  <label label={h.host} xalign={0} />
                </box>
              ))}
            </box>
          )}
        </For>
      </box>
    </box>
  )
}
