import illwill
import ../[tui, element]
import ../../bsky/bsky
import std/[json, strutils, wordwrap, times]

proc renderTimeline*(state: var TUIState, timeline: JsonNode,
                     error = "", status = "", notice = "") =
  let width = max(1, min(86, state.tb.width - 4))
  let x = max(0, (state.tb.width - width) div 2)
  let divider = repeat("-", width)
  var elements: seq[Element] = @[]
  var y = 0

  proc addLine(text = "", color = fgWhite) =
    # Wrap paragraphs separately to retain deliberate line breaks in posts.
    for paragraph in text.splitLines():
      for line in wrapWords(paragraph, width).splitLines():
        elements.add(Element(Label(x: x, y: y, fg: color, text: line)))
        inc y

  addLine("NIMBUS / HOME" & (if status.len > 0: " | " & status else: ""), fgGreen)
  addLine("Up/Down: scroll | R: refresh | L: sign out | Esc: quit")
  addLine(divider, fgBlue)
  if notice.len > 0:
    addLine(notice, fgYellow)

  let feed = timeline{"feed"}
  if error.len > 0:
    addLine(error, fgYellow)
  elif feed.isNil or feed.kind != JArray:
    addLine("No timeline returned. Press R to retry.", fgYellow)
  elif feed.len == 0:
    addLine()
    addLine("Your timeline is empty.", fgYellow)
    addLine("Follow some accounts, then press R to refresh.")
  else:
    for item in feed:
      let post = item{"post"}
      addLine()
      let handle = "@" & post{"author", "handle"}.getStr("unknown")
      let name = post{"author", "displayName"}.getStr().strip()
      addLine((if name.len > 0: name & "  " else: "") & handle, fgCyan)
      let createdAt = post{"record", "createdAt"}.getStr()
      if createdAt.len >= 16 and createdAt[10] == 'T':
        let zone = if createdAt.endsWith("Z"): " UTC" else: ""
        addLine(createdAt[0..9] & " " & createdAt[11..15] & zone)
      addLine()
      let text = post{"record", "text"}.getStr()
      if text.len > 0:
        addLine(text)
      else:
        addLine("[Post with attachment]")
      addLine()
      addLine(divider, fgBlue)

  state.elements = elements
  state.findFocusableElements()
  state.update()

proc mainPageSetup*(state: var TUIState, client: BlueskyClient,
                    refreshing = false, notice = "") =
  state.renderTimeline(nil, (if refreshing: "Refreshing feed..." else: "Loading feed..."))
  state.tb.display()
  var timeline: JsonNode
  var error = ""
  try:
    timeline = client.getPostsFromTimeline()
  except CatchableError:
    error = "Unable to load timeline. Press R to retry or L to sign out."
  let status = if error.len == 0: "Updated " & now().format("HH:mm:ss") else: ""
  state.renderTimeline(timeline, error, status, notice)
