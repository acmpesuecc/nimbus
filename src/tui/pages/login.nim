import illwill

import ./../element
import ./../helpers
import ./../tui

const nimbusLogo = """
███╗░░██╗ ██╗ ███╗░░░███╗ ██████╗░ ██╗░░░██╗ ░██████╗
████╗░██║ ██║ ████╗░████║ ██╔══██╗ ██║░░░██║ ██╔════╝
██╔██╗██║ ██║ ██╔████╔██║ ██████╦╝ ██║░░░██║ ╚█████╗░
██║╚████║ ██║ ██║╚██╔╝██║ ██╔══██╗ ██║░░░██║ ░╚═══██╗
██║░╚███║ ██║ ██║░╚═╝░██║ ██████╦╝ ╚██████╔╝ ██████╔╝
╚═╝░░╚══╝ ╚═╝ ╚═╝░░░░░╚═╝ ╚═════╝   ╚═════╝ ╚═════╝░
"""

proc loginPageSetup*(state: var TUIState) = 
  var center = findCenter(terminalWidth(), terminalHeight())

  state.elements = @[
    Element(Heading(x: center.x, y: center.y - 7, fg: fgGreen, bg: bgNone, text: nimbusLogo, centered: true)),
    Element(Label(x: center.x - 19, y: center.y, fg: fgWhite, bg: bgNone, text: "Handle:")),
    Element(Label(x: center.x - 19, y: center.y + 3, fg: fgWhite, bg: bgNone, text: "Passwd:")),
    Element(InputField(x: center.x - 11, y: center.y, fg: fgWhite, bg: bgBlack, inFocus: false, width: 30, text: "", cursorPos: 0)),
    Element(InputField(x: center.x - 11, y: center.y + 3, fg: fgWhite, bg: bgBlack, inFocus: false, width: 30, text: "", cursorPos: 0))
  ]

  state.findFocusableElements()
  state.initFocus()
  
  state.update()
