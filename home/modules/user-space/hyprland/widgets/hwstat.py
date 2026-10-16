# Hardware stats emitter for the waybar hwmon module (--bar) and the AGS hardware panel (--panel).
# Emits one JSON object per line, per tick, until killed.
import argparse
import glob
import json
import os
import subprocess
import sys
import time

import psutil

TEMP_WARN = 80
TEMP_CRIT = 90
CPU_WARN = 90
MIB = 1024 * 1024

# (chip, label) pairs in priority order for the CPU package temperature
CPU_TEMP_SENSORS = [
    ("coretemp", "Package id 0"),
    ("k10temp", "Tctl"),
    ("k10temp", "Tdie"),
    ("zenpower", "Tdie"),
]

SKIP_DISK_PREFIXES = ("loop", "ram", "zram", "dm-", "sr", "md")


def emit(obj):
    print(json.dumps(obj, ensure_ascii=False), flush=True)


def read_int(path):
    try:
        with open(path) as f:
            return int(f.read().strip())
    except (OSError, ValueError):
        return None


def read_str(path):
    try:
        with open(path) as f:
            return f.read().strip()
    except OSError:
        return None


def num(value):
    try:
        return float(value)
    except ValueError:
        return None


def cpu_temp(temps):
    for chip, label in CPU_TEMP_SENSORS:
        for s in temps.get(chip, []):
            if s.label == label:
                return s.current
    for chip in ("coretemp", "k10temp", "zenpower", "acpitz"):
        if temps.get(chip):
            return temps[chip][0].current
    return None


def temp_list(temps):
    seen = set()
    out = []
    for chip, entries in temps.items():
        for s in entries:
            # Per-core coretemp readings are noise next to the package sensor
            if chip == "coretemp" and s.label.startswith("Core "):
                continue
            if s.current is None or s.current <= 0:
                continue
            label = f"{chip} {s.label}" if s.label else chip
            if label in seen:
                continue
            seen.add(label)
            out.append({"label": label, "value": round(s.current, 1)})
    return out


def gpu_nvidia():
    query = "utilization.gpu,temperature.gpu,memory.used,memory.total,power.draw"
    try:
        res = subprocess.run(
            ["nvidia-smi", f"--query-gpu={query}", "--format=csv,noheader,nounits"],
            capture_output=True, text=True, timeout=2,
        )
    except (OSError, subprocess.TimeoutExpired):
        return None
    lines = res.stdout.strip().splitlines()
    if not lines:
        return None
    fields = [num(f.strip()) for f in lines[0].split(",")]
    if len(fields) < 5:
        return None
    util, temp, used, total, power = fields[:5]
    return {
        "util": util,
        "temp": temp,
        "vram_used": used * MIB if used is not None else None,
        "vram_total": total * MIB if total is not None else None,
        "power": power,
    }


def gpu_amd():
    for dev in sorted(glob.glob("/sys/class/drm/card*/device")):
        util = read_int(f"{dev}/gpu_busy_percent")
        if util is None:
            continue
        temp = power = None
        for hw in glob.glob(f"{dev}/hwmon/hwmon*"):
            t = read_int(f"{hw}/temp1_input")
            if t is not None:
                temp = t / 1000
            p = read_int(f"{hw}/power1_average")
            if p is None:
                p = read_int(f"{hw}/power1_input")
            if p is not None:
                power = p / 1e6
        return {
            "util": util,
            "temp": temp,
            "vram_used": read_int(f"{dev}/mem_info_vram_used"),
            "vram_total": read_int(f"{dev}/mem_info_vram_total"),
            "power": power,
        }
    return None


def default_iface():
    try:
        with open("/proc/net/route") as f:
            next(f)
            for line in f:
                parts = line.split()
                if len(parts) > 1 and parts[1] == "00000000":
                    return parts[0]
    except (OSError, StopIteration):
        pass
    return None


def physical_disks():
    return [
        d for d in os.listdir("/sys/block")
        if not d.startswith(SKIP_DISK_PREFIXES)
    ]


def battery_power():
    for bat in sorted(glob.glob("/sys/class/power_supply/BAT*")):
        status = read_str(f"{bat}/status")
        power = read_int(f"{bat}/power_now")
        if power is None:
            current = read_int(f"{bat}/current_now")
            voltage = read_int(f"{bat}/voltage_now")
            if current is not None and voltage is not None:
                power = current * voltage / 1e6
        if power is not None:
            return {"watts": round(power / 1e6, 1), "status": status}
    return None


def fans():
    out = []
    for chip, entries in psutil.sensors_fans().items():
        for s in entries:
            label = f"{chip} {s.label}" if s.label else chip
            out.append({"label": label, "rpm": s.current})
    return out


def top_procs(n=3):
    procs = []
    for p in psutil.process_iter(["name", "cpu_percent"]):
        cpu = p.info["cpu_percent"]
        if cpu:
            procs.append({"name": p.info["name"], "cpu": round(cpu, 1)})
    procs.sort(key=lambda p: p["cpu"], reverse=True)
    return procs[:n]


def run_bar(interval):
    psutil.cpu_percent()
    while True:
        time.sleep(interval)
        cpu = psutil.cpu_percent()
        temp = cpu_temp(psutil.sensors_temperatures())
        mem = psutil.virtual_memory()
        load = " ".join(f"{v:.2f}" for v in os.getloadavg())

        if temp is not None and temp >= TEMP_CRIT:
            cls = "critical"
        elif cpu >= CPU_WARN or (temp is not None and temp >= TEMP_WARN):
            cls = "warning"
        else:
            cls = "normal"

        text = f"󰻠 {cpu:.0f}%"
        if temp is not None:
            text += f" {temp:.0f}°C"
        used_gib = (mem.total - mem.available) / 1024 ** 3
        total_gib = mem.total / 1024 ** 3
        tooltip = f"CPU {cpu:.0f}%\nLoad {load}\nRAM {used_gib:.1f}/{total_gib:.1f} GiB"
        emit({"text": text, "tooltip": tooltip, "class": cls})


def run_panel(interval, gpu):
    gpu_fn = {"nvidia": gpu_nvidia, "amd": gpu_amd}.get(gpu)
    disks = physical_disks()
    iface = default_iface()

    # Prime delta-based counters
    psutil.cpu_percent(percpu=True)
    list(psutil.process_iter(["cpu_percent"]))
    prev_disk = psutil.disk_io_counters(perdisk=True)
    prev_net = psutil.net_io_counters(pernic=True)
    prev_t = time.monotonic()

    while True:
        time.sleep(interval)
        now = time.monotonic()
        dt = max(now - prev_t, 1e-3)
        prev_t = now

        cores = psutil.cpu_percent(percpu=True)
        temps = psutil.sensors_temperatures()
        freqs = psutil.cpu_freq(percpu=True) or []
        cur_freqs = [f.current for f in freqs if f.current]
        mem = psutil.virtual_memory()
        swap = psutil.swap_memory()
        root = psutil.disk_usage("/")

        disk = psutil.disk_io_counters(perdisk=True)
        read = sum(disk[d].read_bytes - prev_disk[d].read_bytes for d in disks if d in disk and d in prev_disk)
        write = sum(disk[d].write_bytes - prev_disk[d].write_bytes for d in disks if d in disk and d in prev_disk)
        prev_disk = disk

        # Default route can change (wifi <-> ethernet); re-resolve each tick
        iface = default_iface() or iface
        net = psutil.net_io_counters(pernic=True)
        rx = tx = 0
        if iface in net and iface in prev_net:
            rx = net[iface].bytes_recv - prev_net[iface].bytes_recv
            tx = net[iface].bytes_sent - prev_net[iface].bytes_sent
        prev_net = net

        emit({
            "cpu": {
                "percent": round(sum(cores) / len(cores), 1) if cores else 0,
                "cores": [round(c, 1) for c in cores],
                "freq_avg": round(sum(cur_freqs) / len(cur_freqs)) if cur_freqs else None,
                "freq_max": round(max(cur_freqs)) if cur_freqs else None,
                "load": [round(v, 2) for v in os.getloadavg()],
                "temp": cpu_temp(temps),
            },
            "mem": {
                "used": mem.total - mem.available,
                "total": mem.total,
                "swap_used": swap.used,
                "swap_total": swap.total,
            },
            "gpu": gpu_fn() if gpu_fn else None,
            "temps": temp_list(temps),
            "disk": {
                "used": root.used,
                "total": root.total,
                "read": read / dt,
                "write": write / dt,
            },
            "net": {"iface": iface, "rx": rx / dt, "tx": tx / dt},
            "power": {"battery": battery_power(), "fans": fans()},
            "procs": top_procs(),
            "uptime": int(time.time() - psutil.boot_time()),
        })


def main():
    parser = argparse.ArgumentParser(description="Hardware stats emitter (JSON lines)")
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--bar", action="store_true", help="compact waybar output")
    mode.add_argument("--panel", action="store_true", help="full payload for the AGS panel")
    parser.add_argument("--interval", type=float, help="seconds between ticks")
    parser.add_argument("--gpu", choices=["nvidia", "amd", "none"], default="none")
    args = parser.parse_args()

    try:
        if args.bar:
            run_bar(args.interval or 2.0)
        else:
            run_panel(args.interval or 1.0, args.gpu)
    except (BrokenPipeError, KeyboardInterrupt):
        sys.exit(0)


if __name__ == "__main__":
    main()
