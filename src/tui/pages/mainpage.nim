import illwill

import ./../element
import ./../helpers
import ./../tui
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

proc mainPageSetup*(state: var TUIState) = 
  var center = findCenter(terminalWidth(), terminalHeight())
  var client = initBlueskyClient()
  client.authenticate()
  var userHandle = getEnv("BLUESKY_HANDLE", "mebin.in")
  let posts = client.getAllPostsByUser(userHandle)
  let following = client.getAllFollowing(userHandle)


  var cursor_y = 0
  state.elements = @[
    #Element(Label(x: center.x - 19, y: center.y - 11, fg: fgWhite, bg: bgNone, text: "test1:")),
    #Element(Label(x: center.x - 19, y: center.y - 12, fg: fgWhite, bg: bgNone, text: "test2:")),

    #Element(Heading(x: center.x, y: 0, fg: fgGreen, height: 8, bg: bgNone, text: nimbusLogo, centered: false)),
    Element(Label(x: center.x - 19, y: center.y, fg: fgWhite, bg: bgNone, text: "Welcome to mainpage:")),
    Element(Label(x: center.x - 19, y: center.y + 4, fg: fgWhite, bg: bgNone, text: "Posts:")),
    #Element(Button(x: center.x - 11, y: center.y + 6, fg: fgWhite, bg: bgBlack, inFocus: false, text: "Posts", width: 30, height: 1, action: proc () = getPosts(state)))
  ]
  #Adding heading as Label, cause with how Headings are rendered, it's not possible to scroll down, this can be a temp fix if heading is modified
  let splitString = nimbusLogo.splitLines()
  for i, line in splitString:
    cursor_y += 1
    state.elements.add(Element(Label(x: center.x - 19, y: cursor_y, fg: fgGreen, bg: bgNone, text: line)))

  cursor_y = center.y+4

  for post in posts:
    var text = post["text"].getStr()
    cursor_y += 2
    state.elements.add(Element(Label(x: center.x - 19, y: cursor_y, fg: fgWhite, bg: bgNone, text: text)))
    

  cursor_y += 4
  state.elements.add(Element(Label(x: center.x - 19, y: cursor_y, fg: fgWhite, bg: bgNone, text: "Following:")))
  for account in following:
    var displayNameString = "Display Name: " & account["displayName"].getStr()
    var handleString = "Handle: " & account["handle"].getStr()
    cursor_y += 2
    state.elements.add(Element(Label(x: center.x - 19, y: cursor_y, fg: fgWhite, bg: bgNone, text: displayNameString)))
    cursor_y += 2
    state.elements.add(Element(Label(x: center.x - 19, y: cursor_y, fg: fgWhite, bg: bgNone, text: handleString)))
    cursor_y += 1

  #print text from 1 to 20 for testing purposes (testing scrolling rn lel)
  cursor_y += 4
  state.elements.add(Element(Label(x: center.x - 19, y: cursor_y + 4, fg: fgWhite, bg: bgNone, text: "Random Numbers:")))
  for i in 1..20:
    var text = "Text: " & $i
    state.elements.add(Element(Label(x: center.x - 19, y: cursor_y + 2, fg: fgWhite, bg: bgNone, text: text)))
    cursor_y += 2  

  state.findFocusableElements()
  state.initFocus()
  
  state.update()

