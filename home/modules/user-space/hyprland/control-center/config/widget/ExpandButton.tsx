import type { Accessor, Setter } from "ags"

// Chevron toggle for collapsible section lists
export default function ExpandButton({
  expanded,
  setExpanded,
}: {
  expanded: Accessor<boolean>
  setExpanded: Setter<boolean>
}) {
  return (
    <button class="expand-btn" onClicked={() => setExpanded((e) => !e)}>
      <image iconName={expanded((e) => (e ? "pan-down-symbolic" : "pan-end-symbolic"))} />
    </button>
  )
}
