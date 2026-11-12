import GLib from "gi://GLib"
import Gtk from "gi://Gtk?version=4.0"
import AstalIO from "gi://AstalIO"
import { createState } from "ags"
import type { Accessor } from "ags"
import { readFile } from "ags/file"
import { execAsync } from "ags/process"
import { interval } from "ags/time"

type Verdict = "ok" | "tight" | "over" | "exhausted"

// Per-window shape from widgets/ollama-usage.nix
type Window = {
  used: number
  resets_at: number
  window_h: number
  recent: { rate_per_h: number; projected: number; exhausts_at: number | null } | null
  average: { projected: number } | null
  verdict: Verdict
}

type Usage = {
  ok: boolean
  error: string | null
  stale: boolean
  fetched_at: number | null
  session: Window | null
  weekly: Window | null
}

// Reads the poller's cache, so this can be faster than the 60s API poll
const POLL_MS = 5000

function ollamaEnabled() {
  try {
    const path = GLib.get_user_config_dir() + "/ags/features.json"
    return JSON.parse(readFile(path)).ollamaUsage === true
  } catch {
    return false
  }
}

function countdown(epoch: number) {
  const s = Math.max(0, epoch - Math.floor(Date.now() / 1000))
  const d = Math.floor(s / 86400)
  const h = Math.floor((s % 86400) / 3600)
  const m = Math.floor((s % 3600) / 60)
  return d > 0 ? `${d}d ${h}h` : `${h}h ${String(m).padStart(2, "0")}m`
}

function headline(w: Window | null) {
  return w ? `${w.used.toFixed(0)}% · resets in ${countdown(w.resets_at)}` : "--"
}

function projection(w: Window | null) {
  if (!w) return ""
  if (w.verdict === "exhausted") return `Limit reached · resets in ${countdown(w.resets_at)}`
  const parts: string[] = []
  if (w.recent) {
    let s = `${w.recent.rate_per_h.toFixed(1)}%/h → ${w.recent.projected.toFixed(0)}% at reset`
    if (w.recent.exhausts_at) s += ` · limit in ${countdown(w.recent.exhausts_at)}`
    parts.push(s)
  } else {
    parts.push("Collecting samples…")
  }
  if (w.average) parts.push(`avg → ${w.average.projected.toFixed(0)}%`)
  return parts.join(" · ")
}

function status(u: Usage) {
  if (u.error) return "Poll failed"
  return u.stale ? "Stale" : ""
}

function WindowRow({ label, usage, pick }: { label: string; usage: Accessor<Usage>; pick: (u: Usage) => Window | null }) {
  return (
    <box orientation={Gtk.Orientation.VERTICAL} spacing={2}>
      <box spacing={8}>
        <label label={label} hexpand xalign={0} />
        <label class="ollama-meta" label={usage((u) => headline(pick(u)))} />
      </box>
      <levelbar
        class={usage((u) => `ollama-bar ${pick(u)?.verdict ?? "ok"}`)}
        value={usage((u) => Math.min(pick(u)?.used ?? 0, 100))}
        minValue={0}
        maxValue={100}
      />
      <label class="ollama-meta" label={usage((u) => projection(pick(u)))} xalign={0} />
    </box>
  )
}

// Ollama Cloud usage + limit projection; polls only while the control center is shown.
export default function Ollama({ shown }: { shown: Accessor<boolean> }) {
  if (!ollamaEnabled()) return <box visible={false} />

  const [usage, setUsage] = createState<Usage>({
    ok: false,
    error: null,
    stale: true,
    fetched_at: null,
    session: null,
    weekly: null,
  })

  const refresh = () =>
    execAsync(["ollama-usage"])
      .then((out) => setUsage(JSON.parse(out)))
      .catch((e) =>
        setUsage({ ok: false, error: String(e), stale: true, fetched_at: null, session: null, weekly: null }),
      )

  let timer: AstalIO.Time | null = null
  shown.subscribe(() => {
    if (shown.get()) {
      if (timer) return
      refresh()
      timer = interval(POLL_MS, refresh)
    } else {
      timer?.cancel()
      timer = null
    }
  })

  return (
    <box class="section ollama" orientation={Gtk.Orientation.VERTICAL} spacing={6}>
      <box class="section-header" spacing={8}>
        <label label="Ollama Cloud" hexpand xalign={0} class="section-title" />
        <label
          class="ollama-meta stale"
          label={usage(status)}
          visible={usage((u) => status(u) !== "")}
          tooltipText={usage((u) => u.error ?? "")}
        />
      </box>
      <WindowRow label="Session" usage={usage} pick={(u) => u.session} />
      <WindowRow label="Weekly" usage={usage} pick={(u) => u.weekly} />
    </box>
  )
}
