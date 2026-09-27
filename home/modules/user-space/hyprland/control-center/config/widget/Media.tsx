import Gtk from "gi://Gtk?version=4.0"
import AstalMpris from "gi://AstalMpris"
import { For, createBinding } from "ags"

function PlayerRow({ player }: { player: AstalMpris.Player }) {
  const title = createBinding(player, "title")
  const artist = createBinding(player, "artist")
  const coverArt = createBinding(player, "coverArt")
  const canPrev = createBinding(player, "canGoPrevious")
  const canNext = createBinding(player, "canGoNext")
  const canControl = createBinding(player, "canControl")
  const isPlaying = createBinding(player, "playbackStatus")(
    (s: AstalMpris.PlaybackStatus) => s === AstalMpris.PlaybackStatus.PLAYING
  )

  return (
    <box class="media-player" spacing={8}>
      <box overflow={Gtk.Overflow.HIDDEN} css="border-radius: 8px;" widthRequest={48} heightRequest={48}>
        <image pixelSize={48} file={coverArt} />
      </box>
      <box orientation={Gtk.Orientation.VERTICAL} valign={Gtk.Align.CENTER} hexpand>
        <label label={title} xalign={0} ellipsize={3} class="media-title" />
        <label label={artist} xalign={0} ellipsize={3} class="media-artist" />
      </box>
      <box valign={Gtk.Align.CENTER} spacing={2}>
        <button class="media-btn" onClicked={() => player.previous()} visible={canPrev}>
          <image iconName="media-skip-backward-symbolic" />
        </button>
        <button class="media-btn" onClicked={() => player.play_pause()} visible={canControl}>
          <box>
            <image iconName="media-playback-pause-symbolic" visible={isPlaying} />
            <image
              iconName="media-playback-start-symbolic"
              visible={isPlaying((p: boolean) => !p)}
            />
          </box>
        </button>
        <button class="media-btn" onClicked={() => player.next()} visible={canNext}>
          <image iconName="media-skip-forward-symbolic" />
        </button>
      </box>
    </box>
  )
}

export default function Media() {
  const mpris = AstalMpris.get_default()
  const players = createBinding(mpris, "players")
  const hasPlayers = players((p: AstalMpris.Player[]) => p.length > 0)

  return (
    <box class="section" orientation={Gtk.Orientation.VERTICAL} spacing={4} visible={hasPlayers}>
      <box class="section-header" spacing={8}>
        <image iconName="multimedia-player-symbolic" />
        <label label="Media" hexpand xalign={0} class="section-title" />
      </box>
      <For each={players}>
        {(player: AstalMpris.Player) => <PlayerRow player={player} />}
      </For>
    </box>
  )
}
