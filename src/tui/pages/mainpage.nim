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
  var client = initBlueskyClient()
  client.authenticate()
  let userHandle = "mebin.in"
  let posts = client.getAllPostsByUser(userHandle)
  
  state.elements = @[
    Element(Heading(x: center.x, y: center.y - 7, fg: fgGreen, bg: bgNone, text: nimbusLogo, centered: true)),
    Element(Label(x: center.x - 19, y: center.y, fg: fgWhite, bg: bgNone, text: "Welcome to mainpage:")),
    Element(Label(x: center.x - 19, y: center.y + 4, fg: fgWhite, bg: bgNone, text: "Posts:")),
    #Element(Button(x: center.x - 11, y: center.y + 6, fg: fgWhite, bg: bgBlack, inFocus: false, text: "Posts", width: 30, height: 1, action: proc () = getPosts(state)))
  ]

  var lineBreaker: int = 0
  for post in posts:
    var text = post["text"].getStr()
    state.elements.add(Element(Label(x: center.x - 19, y: center.y + 6 + lineBreaker, fg: fgWhite, bg: bgNone, text: text)))
    lineBreaker += 2
  

  state.findFocusableElements()
  state.initFocus()
  
  state.update()
