import Gtk from "gi://Gtk?version=4.0"
import AstalPowerProfiles from "gi://AstalPowerProfiles"
import { With, createBinding } from "ags"

const PROFILE_ICONS: Record<string, string> = {
  "performance": "power-profile-performance-symbolic",
  "balanced": "power-profile-balanced-symbolic",
  "power-saver": "power-profile-power-saver-symbolic",
}

const PROFILE_LABELS: Record<string, string> = {
  "performance": "Performance",
  "balanced": "Balanced",
  "power-saver": "Power Saver",
}

const DEGRADED_REASONS: Record<string, string> = {
  "lap-detected": "Performance limited: lap detected",
  "high-operating-temperature": "Performance limited: high temperature",
}

export default function PowerProfile() {
  const pp = AstalPowerProfiles.get_default()
  const activeProfile = createBinding(pp, "activeProfile")
  const profiles = createBinding(pp, "profiles")
  const degraded = createBinding(pp, "performanceDegraded")

  return (
    <box class="section" orientation={Gtk.Orientation.VERTICAL} spacing={4}>
      <box class="section-header" spacing={8}>
        <image
          iconName={activeProfile((p: string) => PROFILE_ICONS[p] ?? "power-profile-balanced-symbolic")}
        />
        <label label="Power Profile" hexpand xalign={0} class="section-title" />
        <label
          class="profile-active"
          label={activeProfile((p: string) => PROFILE_LABELS[p] ?? p ?? "")}
        />
      </box>
      <With value={profiles}>
        {(list: AstalPowerProfiles.Profile[]) =>
          list.length === 0 ? (
            <label class="profile-note" xalign={0} label="power-profiles-daemon unavailable" />
          ) : (
            <box class="profile-buttons" spacing={4} homogeneous>
              {list.map(({ profile, driver }) => (
                <button
                  class={activeProfile((active: string) =>
                    active === profile ? "profile-btn active" : "profile-btn"
                  )}
                  onClicked={() => pp.set_active_profile(profile)}
                  tooltipText={driver ? `Driver: ${driver}` : profile}
                >
                  <box orientation={Gtk.Orientation.VERTICAL} spacing={2}>
                    <image iconName={PROFILE_ICONS[profile] ?? "power-profile-balanced-symbolic"} />
                    <label label={PROFILE_LABELS[profile] ?? profile} />
                  </box>
                </button>
              ))}
            </box>
          )
        }
      </With>
      <label
        class="profile-note"
        xalign={0}
        visible={degraded((d: string) => !!d)}
        label={degraded((d: string) => DEGRADED_REASONS[d] ?? `Performance limited: ${d}`)}
      />
    </box>
  )
}
