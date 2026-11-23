import Gtk from "gi://Gtk?version=4.0"
import AstalWp from "gi://AstalWp"
import { For, createBinding, createState } from "ags"
import ExpandButton from "./ExpandButton"

function SinkRow({ endpoint }: { endpoint: AstalWp.Endpoint }) {
  const isDefault = createBinding(endpoint, "isDefault")

  return (
    <button
      class="sink-row"
      onClicked={() => endpoint.set_is_default(true)}
    >
      <box spacing={8}>
        <image iconName={createBinding(endpoint, "volumeIcon")} />
        <label
          label={createBinding(endpoint, "description")}
          hexpand
          xalign={0}
          ellipsize={3}
        />
        <image iconName="object-select-symbolic" visible={isDefault} />
      </box>
    </button>
  )
}

export default function Audio() {
  const wp = AstalWp.get_default()!
  const { defaultSpeaker: speaker } = wp

  const speakers = createBinding(wp.audio, "speakers")
  const showSinkList = speakers((s: AstalWp.Endpoint[]) => s.length > 1)
  const [expanded, setExpanded] = createState(false)

  return (
    <box class="section" orientation={Gtk.Orientation.VERTICAL} spacing={4}>
      <box class="section-header" spacing={8}>
        <image iconName={createBinding(speaker, "volumeIcon")} />
        <label label="Sound" hexpand xalign={0} class="section-title" />
        <button
          class="mute-btn"
          onClicked={() => speaker.set_mute(!speaker.mute)}
        >
          <image
            iconName={createBinding(speaker, "mute")((m: boolean) =>
              m ? "audio-volume-muted-symbolic" : "audio-volume-high-symbolic"
            )}
          />
        </button>
        <box visible={showSinkList}>
          <ExpandButton expanded={expanded} setExpanded={setExpanded} />
        </box>
      </box>
      <box spacing={8}>
        <image iconName="audio-volume-low-symbolic" css="margin-left: 4px;" />
        <slider
          class="volume-slider"
          hexpand
          value={createBinding(speaker, "volume")}
          onChangeValue={({ value }) => speaker.set_volume(value)}
        />
        <label
          label={createBinding(speaker, "volume")((v: number) => `${Math.round(v * 100)}%`)}
          widthChars={4}
          xalign={1}
        />
      </box>
      <revealer revealChild={expanded} visible={showSinkList}>
        <box class="sink-list" orientation={Gtk.Orientation.VERTICAL} spacing={2}>
          <For each={speakers}>
            {(ep: AstalWp.Endpoint) => <SinkRow endpoint={ep} />}
          </For>
        </box>
      </revealer>
    </box>
  )
}
