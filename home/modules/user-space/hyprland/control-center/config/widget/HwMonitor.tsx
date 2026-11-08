import app from "ags/gtk4/app"
import Astal from "gi://Astal?version=4.0"
import Gtk from "gi://Gtk?version=4.0"
import Gdk from "gi://Gdk?version=4.0"
import AstalIO from "gi://AstalIO"
import AstalPowerProfiles from "gi://AstalPowerProfiles"
import { For, createBinding, createState } from "ags"
import type { Accessor } from "ags"
import { subprocess } from "ags/process"
import Sparkline, { HISTORY } from "./Sparkline"
import { dismiss } from "./Overlay"

// Shape of one `hwstat --panel` line (widgets/hwstat.py)
type Stats = {
  cpu: {
    percent: number
    cores: number[]
    freq_avg: number | null
    freq_max: number | null
    load: number[]
    temp: number | null
  }
  mem: { used: number; total: number; swap_used: number; swap_total: number }
  gpu: {
    util: number | null
    temp: number | null
    vram_used: number | null
    vram_total: number | null
    power: number | null
  } | null
  temps: { label: string; value: number }[]
  disk: { used: number; total: number; read: number; write: number }
  net: { iface: string | null; rx: number; tx: number }
  power: {
    battery: { watts: number; status: string | null } | null
    fans: { label: string; rpm: number }[]
  }
  procs: { name: string; cpu: number }[]
  uptime: number
}

const PROFILE_LABELS: Record<string, string> = {
  "performance": "Performance",
  "balanced": "Balanced",
  "power-saver": "Power Saver",
}

const GiB = 1024 ** 3

function fmtBytes(b: number) {
  return b >= GiB ? `${(b / GiB).toFixed(1)} GiB` : `${Math.round(b / 1024 ** 2)} MiB`
}

function fmtRate(b: number) {
  if (b >= 1e6) return `${(b / 1e6).toFixed(1)} MB/s`
  if (b >= 1e3) return `${(b / 1e3).toFixed(0)} kB/s`
  return `${Math.round(b)} B/s`
}

function fmtTemp(t: number | null | undefined) {
  return t == null ? "--" : `${Math.round(t)}°C`
}

function fmtUptime(s: number) {
  const d = Math.floor(s / 86400)
  const h = Math.floor((s % 86400) / 3600)
  const m = Math.floor((s % 3600) / 60)
  return d > 0 ? `${d}d ${h}h ${m}m` : `${h}h ${m}m`
}

function Header({ icon, title, value }: { icon: string; title: string; value?: Accessor<string> }) {
  return (
    <box class="section-header" spacing={8}>
      <image iconName={icon} />
      <label label={title} hexpand xalign={0} class="section-title" />
      {value && <label label={value} class="hw-stat" />}
    </box>
  )
}

function Row({ label, value }: { label: string | Accessor<string>; value: Accessor<string> }) {
  return (
    <box class="hw-row" spacing={8}>
      <label label={label} class="hw-sub" hexpand xalign={0} ellipsize={3} />
      <label label={value} class="hw-stat" />
    </box>
  )
}

export default function HwMonitor() {
  const { TOP, RIGHT } = Astal.WindowAnchor
  const pp = AstalPowerProfiles.get_default()

  const [stats, setStats] = createState<Stats | null>(null)
  const [cpuHist, setCpuHist] = createState<number[]>([])
  const [gpuHist, setGpuHist] = createState<number[]>([])
  const [rxHist, setRxHist] = createState<number[]>([])

  let proc: AstalIO.Process | null = null

  const push = (hist: Accessor<number[]>, set: (v: number[]) => void, v: number) =>
    set([...hist.get().slice(-(HISTORY - 1)), v])

  function start() {
    if (proc) return
    setCpuHist([])
    setGpuHist([])
    setRxHist([])
    proc = subprocess(
      ["hwstat", "--panel"],
      (line) => {
        try {
          const s: Stats = JSON.parse(line)
          setStats(s)
          push(cpuHist, setCpuHist, s.cpu.percent)
          if (s.gpu?.util != null) push(gpuHist, setGpuHist, s.gpu.util)
          push(rxHist, setRxHist, s.net.rx + s.net.tx)
        } catch (e) {
          console.error(e)
        }
      },
      (err) => console.error(err),
    )
  }

  function stop() {
    proc?.kill()
    proc = null
  }

  // Derive a label from the latest sample; `fallback` before the first tick
  const pick = <T,>(fn: (s: Stats) => T, fallback: T) => stats((s) => (s ? fn(s) : fallback))

  return (
    <window
      visible={false}
      name="hw-monitor"
      namespace="hw-monitor"
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
      <box
        orientation={Gtk.Orientation.VERTICAL}
        spacing={8}
        css="padding: 16px;"
        widthRequest={400}
      >
        <box class="section" orientation={Gtk.Orientation.VERTICAL} spacing={4}>
          <Header
            icon="computer-symbolic"
            title="CPU"
            value={pick((s) => `${Math.round(s.cpu.percent)}%  ${fmtTemp(s.cpu.temp)}`, "--")}
          />
          <Sparkline values={cpuHist} max={100} class="spark-cpu" />
          <Row
            label="Clock avg / max"
            value={pick(
              (s) =>
                s.cpu.freq_avg == null
                  ? "--"
                  : `${(s.cpu.freq_avg / 1000).toFixed(2)} / ${((s.cpu.freq_max ?? 0) / 1000).toFixed(2)} GHz`,
              "--",
            )}
          />
          <Row label="Load 1 / 5 / 15" value={pick((s) => s.cpu.load.join(" / "), "--")} />
          <box class="core-bars" spacing={2} homogeneous>
            <For each={pick((s) => s.cpu.cores.map((_, i) => i), [] as number[])}>
              {(i: number) => (
                <levelbar
                  class="core-bar"
                  orientation={Gtk.Orientation.VERTICAL}
                  inverted
                  heightRequest={24}
                  minValue={0}
                  maxValue={100}
                  value={pick((s) => s.cpu.cores[i] ?? 0, 0)}
                  tooltipText={`Core ${i}`}
                />
              )}
            </For>
          </box>
        </box>

        <box class="section" orientation={Gtk.Orientation.VERTICAL} spacing={4}>
          <Header
            icon="drive-harddisk-solidstate-symbolic"
            title="Memory"
            value={pick((s) => `${fmtBytes(s.mem.used)} / ${fmtBytes(s.mem.total)}`, "--")}
          />
          <levelbar class="hw-bar" minValue={0} maxValue={1} value={pick((s) => s.mem.used / s.mem.total, 0)} />
          <Row
            label="Swap"
            value={pick(
              (s) => (s.mem.swap_total ? `${fmtBytes(s.mem.swap_used)} / ${fmtBytes(s.mem.swap_total)}` : "none"),
              "--",
            )}
          />
        </box>

        <box class="section" orientation={Gtk.Orientation.VERTICAL} spacing={4} visible={pick((s) => !!s.gpu, false)}>
          <Header
            icon="video-display-symbolic"
            title="GPU"
            value={pick((s) => `${Math.round(s.gpu?.util ?? 0)}%  ${fmtTemp(s.gpu?.temp)}`, "--")}
          />
          <Sparkline values={gpuHist} max={100} class="spark-gpu" />
          <Row
            label="VRAM"
            value={pick(
              (s) =>
                s.gpu?.vram_used != null && s.gpu.vram_total != null
                  ? `${fmtBytes(s.gpu.vram_used)} / ${fmtBytes(s.gpu.vram_total)}`
                  : "--",
              "--",
            )}
          />
          <Row label="Power" value={pick((s) => (s.gpu?.power != null ? `${s.gpu.power.toFixed(1)} W` : "--"), "--")} />
        </box>

        <box class="section" orientation={Gtk.Orientation.VERTICAL} spacing={2}>
          <Header icon="temperature-symbolic" title="Temperatures" />
          <For each={pick((s) => s.temps.map((t) => t.label), [] as string[])}>
            {(label: string) => (
              <Row label={label} value={pick((s) => fmtTemp(s.temps.find((t) => t.label === label)?.value), "--")} />
            )}
          </For>
        </box>

        <box class="section" orientation={Gtk.Orientation.VERTICAL} spacing={4}>
          <Header
            icon="network-transmit-receive-symbolic"
            title="Disk & Network"
            value={pick((s) => s.net.iface ?? "offline", "--")}
          />
          <Row
            label="/"
            value={pick((s) => `${fmtBytes(s.disk.used)} / ${fmtBytes(s.disk.total)}`, "--")}
          />
          <levelbar class="hw-bar" minValue={0} maxValue={1} value={pick((s) => s.disk.used / s.disk.total, 0)} />
          <Row label="Disk read / write" value={pick((s) => `${fmtRate(s.disk.read)} / ${fmtRate(s.disk.write)}`, "--")} />
          <Sparkline values={rxHist} class="spark-net" />
          <Row label="Net down / up" value={pick((s) => `${fmtRate(s.net.rx)} / ${fmtRate(s.net.tx)}`, "--")} />
        </box>

        <box class="section" orientation={Gtk.Orientation.VERTICAL} spacing={2}>
          <Header icon="battery-good-symbolic" title="Power" />
          <Row
            label="Profile"
            value={createBinding(pp, "activeProfile")((p: string) => PROFILE_LABELS[p] ?? p ?? "--")}
          />
          <box visible={pick((s) => !!s.power.battery, false)}>
            <Row
              label={pick((s) => `Battery (${s.power.battery?.status ?? "?"})`, "Battery")}
              value={pick((s) => `${s.power.battery?.watts.toFixed(1) ?? "--"} W`, "--")}
            />
          </box>
          <For each={pick((s) => s.power.fans.map((_, i) => i), [] as number[])}>
            {(i: number) => (
              <Row
                label={pick((s) => s.power.fans[i]?.label ?? "fan", "fan")}
                value={pick((s) => `${s.power.fans[i]?.rpm ?? 0} RPM`, "--")}
              />
            )}
          </For>
        </box>

        <box class="section" orientation={Gtk.Orientation.VERTICAL} spacing={2}>
          <Header icon="system-run-symbolic" title="Top processes" />
          <For each={pick((s) => s.procs.map((_, i) => i), [] as number[])}>
            {(i: number) => (
              <Row
                label={pick((s) => s.procs[i]?.name ?? "", "")}
                value={pick((s) => `${(s.procs[i]?.cpu ?? 0).toFixed(1)}%`, "--")}
              />
            )}
          </For>
          <Row label="Uptime" value={pick((s) => fmtUptime(s.uptime), "--")} />
        </box>
      </box>
    </window>
  )
}
