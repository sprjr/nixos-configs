import Gtk from "gi://Gtk?version=4.0"
import type { Accessor } from "ags"

export const HISTORY = 60

type Props = {
  values: Accessor<number[]>
  // Fixed ceiling (e.g. 100 for percentages); auto-scales to the buffer max when omitted
  max?: number
  class?: string
}

// Line graph of the last HISTORY samples, newest at the right edge. Color comes from the
// widget's CSS `color`, so each instance is themed from style.scss.
export default function Sparkline({ values, max, class: cls = "" }: Props) {
  return (
    <Gtk.DrawingArea
      class={`sparkline ${cls}`}
      hexpand
      heightRequest={36}
      $={(self: Gtk.DrawingArea) => {
        self.set_draw_func((_area, cr, width, height) => {
          const data = values.get()
          if (data.length < 2) return
          const top = max ?? Math.max(...data, 1)
          const step = width / (HISTORY - 1)
          const x = (i: number) => width - (data.length - 1 - i) * step
          const y = (v: number) => height - (Math.min(v, top) / top) * (height - 2) - 1
          const { red, green, blue } = self.get_color()

          // Filled area under the line
          cr.moveTo(x(0), height)
          data.forEach((v, i) => cr.lineTo(x(i), y(v)))
          cr.lineTo(x(data.length - 1), height)
          cr.closePath()
          cr.setSourceRGBA(red, green, blue, 0.2)
          cr.fill()

          // Line
          data.forEach((v, i) => (i === 0 ? cr.moveTo(x(i), y(v)) : cr.lineTo(x(i), y(v))))
          cr.setSourceRGBA(red, green, blue, 1)
          cr.setLineWidth(1.5)
          cr.stroke()
        })
        values.subscribe(() => self.queue_draw())
      }}
    />
  )
}
