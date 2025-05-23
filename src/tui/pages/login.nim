import illwill

import ./../element
import ./../helpers
import ./../tui
import ./../../nimbus
import ./mainpage

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

  

  proc mainpageRoute() =
    proc initTUIState(state: var TUIState) = #TODO: Somebody plj help, I'm not able to import this function from nimbus.nim, just put this here for now
      state.tb = newTerminalBuffer(terminalWidth(), terminalHeight())
      state.elements = @[]
      state.focusableIdxs = @[]
      state.currentFocus = 0


    var tuiState: TUIState 
    tuiState.initTUIState()
    tuiState.mainPageSetup()
    tuiState.tb.display()

    while true:
      var key = getKey() 
      var redraw = false
      
      case key 
      of Key.Tab:
        redraw = tuiState.toggleFocus() 
      else:
        redraw = tuiState.handleKeyInput(key)

      if redraw:
        tuiState.update()
        tuiState.tb.display()
    
  proc writeToEnv(Handle, Password: InputField) =
    let PDSHOST : string = "PDSHOST=https://bsky.social" & "\n"
    let BLUESKY_HANDLE : string = "BLUESKY_HANDLE=" & Handle.text & "\n"
    let APP_PASSWORD : string = "APP_PASSWORD=" & Password.text & "\n"

    writeFile(".env", PDSHOST & BLUESKY_HANDLE & APP_PASSWORD)
    writeFile("src/bsky/.env", PDSHOST & BLUESKY_HANDLE & APP_PASSWORD)

    mainpageRoute()

  var BLUESKY_HANDLE : InputField = InputField(x: center.x - 11, y: center.y, fg: fgWhite, bg: bgBlack, inFocus: false, width: 30, text: "", cursorPos: 0)
  var APP_PASSWORD : InputField = InputField(x: center.x - 11, y: center.y + 3, fg: fgWhite, bg: bgBlack, inFocus: false, width: 30, text: "", cursorPos: 0)
  state.elements = @[
    Element(Heading(x: center.x, y: center.y - 7, fg: fgGreen, bg: bgNone, text: nimbusLogo, centered: true)),
    Element(Label(x: center.x - 19, y: center.y, fg: fgWhite, bg: bgNone, text: "Handle:")),
    Element(Label(x: center.x - 19, y: center.y + 3, fg: fgWhite, bg: bgNone, text: "Passwd:")),
    Element(BLUESKY_HANDLE),
    Element(APP_PASSWORD),
    Element(Button(x: center.x - 11, y: center.y + 6, fg: fgWhite, bg: bgBlack, inFocus: false, text: "Login", width: 30, height: 1, action: proc() = writeToEnv(BLUESKY_HANDLE, APP_PASSWORD)))
  ]

  state.findFocusableElements()
  state.initFocus()
  
  state.update()
