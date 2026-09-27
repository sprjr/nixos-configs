import Gtk from "gi://Gtk?version=4.0"
import AstalPowerProfiles from "gi://AstalPowerProfiles"
import { createBinding } from "ags"

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

export default function PowerProfile() {
  const pp = AstalPowerProfiles.get_default()
  const activeProfile = createBinding(pp, "activeProfile")
  const profiles = pp.get_profiles()

  return (
    <box class="section" orientation={Gtk.Orientation.VERTICAL} spacing={4}>
      <box class="section-header" spacing={8}>
        <image
          iconName={activeProfile((p: string) => PROFILE_ICONS[p] ?? "power-profile-balanced-symbolic")}
        />
        <label label="Power Profile" hexpand xalign={0} class="section-title" />
      </box>
      <box class="profile-buttons" spacing={4} homogeneous>
        {profiles.map(({ profile }) => (
          <button
            class={activeProfile((active: string) =>
              active === profile ? "profile-btn active" : "profile-btn"
            )}
            onClicked={() => pp.set_active_profile(profile)}
            tooltipText={profile}
          >
            <box orientation={Gtk.Orientation.VERTICAL} spacing={2}>
              <image iconName={PROFILE_ICONS[profile] ?? "power-profile-balanced-symbolic"} />
              <label label={PROFILE_LABELS[profile] ?? profile} />
            </box>
          </button>
        ))}
      </box>
    </box>
  )
}
