import illwill

import ./../element
import ./../helpers
import ./../tui
import ./../../bsky/bsky
import json

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

  proc getPosts() =
    var client = initBlueskyClient()
    client.authenticate()
    let userHandle = "mebin.in"
    let posts = client.getAllPostsByUser(userHandle)
    for post in posts:
      state.elements.add(Element(Label(x: center.x - 19, y: center.y, fg: fgWhite, bg: bgNone, text: post.getStr())))


  state.elements = @[
    Element(Heading(x: center.x, y: center.y - 7, fg: fgGreen, bg: bgNone, text: nimbusLogo, centered: true)),
    Element(Label(x: center.x - 19, y: center.y, fg: fgWhite, bg: bgNone, text: "Welcome to mainpage:")),
    Element(Button(x: center.x - 11, y: center.y + 6, fg: fgWhite, bg: bgBlack, inFocus: false, text: "Posts", width: 30, height: 1, action: proc() = getPosts()))
  ]

  state.findFocusableElements()
  state.initFocus()
  
  state.update()
