import illwill
import ./../element
import ./../helpers
import ./../client
import ./../../bsky/bsky
import json
import std/strutils

const nimbusLogo = """
███╗░░██╗ ██╗ ███╗░░░███╗ ██████╗░ ██╗░░░██╗ ░██████╗
████╗░██║ ██║ ████╗░████║ ██╔══██╗ ██║░░░██║ ██╔════╝
██╔██╗██║ ██║ ██╔████╔██║ ██████╦╝ ██║░░░██║ ╚█████╗░
██║╚████║ ██║ ██║╚██╔╝██║ ██╔══██╗ ██║░░░██║ ░╚═══██╗
██║░╚███║ ██║ ██║░╚═╝░██║ ██████╦╝ ╚██████╔╝ ██████╔╝
╚═╝░░╚══╝ ╚═╝ ╚═╝░░░░░╚═╝ ╚═════╝   ╚═════╝ ╚═════╝░
"""

proc mainPageSetup*(state: var TUIState, client: Client) =
  let center = findCenter(terminalWidth(), terminalHeight())
  let userHandle = "mebin.in"

  let posts = client.getAllPostsByUser(userHandle)
  let following = client.getAllFollowing(userHandle)

  var cursor_y = 0
  state.elements = @[
    Element(Label(x: center.x - 19, y: center.y, fg: fgWhite, bg: bgNone, text: "Welcome to mainpage:")),
    Element(Label(x: center.x - 19, y: center.y + 4, fg: fgWhite, bg: bgNone, text: "Posts:"))
  ]

  # Add Nimbus logo as scrollable labels
  let splitString = nimbusLogo.splitLines()
  for line in splitString:
    cursor_y += 1
    state.elements.add(Element(Label(x: center.x - 19, y: cursor_y, fg: fgGreen, bg: bgNone, text: line)))

  cursor_y = center.y + 4

  for post in posts:
    let text = post["text"].getStr()
    cursor_y += 2
    state.elements.add(Element(Label(x: center.x - 19, y: cursor_y, fg: fgWhite, bg: bgNone, text: text)))

  cursor_y += 4
  state.elements.add(Element(Label(x: center.x - 19, y: cursor_y, fg: fgWhite, bg: bgNone, text: "Following:")))

  for account in following:
    let displayNameString = "Display Name: " & account["displayName"].getStr()
    let handleString = "Handle: " & account["handle"].getStr()
    cursor_y += 2
    state.elements.add(Element(Label(x: center.x - 19, y: cursor_y, fg: fgWhite, bg: bgNone, text: displayNameString)))
    cursor_y += 2
    state.elements.add(Element(Label(x: center.x - 19, y: cursor_y, fg: fgWhite, bg: bgNone, text: handleString)))
    cursor_y += 1

  cursor_y += 4
  state.elements.add(Element(Label(x: center.x - 19, y: cursor_y + 4, fg: fgWhite, bg: bgNone, text: "Random Numbers:")))

  for i in 1..20:
    let text