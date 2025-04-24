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

proc mainPageSetup*(state: var TUIState) = 
  var center = findCenter(terminalWidth(), terminalHeight())

  state.elements = @[
    Element(Heading(x: center.x, y: center.y - 7, fg: fgGreen, bg: bgNone, text: nimbusLogo, centered: true)),
    Element(Label(x: center.x - 19, y: center.y, fg: fgWhite, bg: bgNone, text: "Welcome to mainpage:")),
  ]

  state.findFocusableElements()
  state.initFocus()
  
  state.update()
