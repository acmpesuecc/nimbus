import illwill

import ./tui/tui
import ./tui/pages/login

type 
  Pages = enum 
    login, main, settings

proc exitProc() {.noconv.} =
  illwillDeinit()
  showCursor()
  quit(0)

proc initTUIState*(state: var TUIState) = 
  state.tb = newTerminalBuffer(terminalWidth(), terminalHeight())
  state.elements = @[]
  state.focusableIdxs = @[]
  state.currentFocus = 0

when isMainModule:
  illwillInit(fullscreen=true)
  setControlCHook(exitProc)
  hideCursor()
 
  var tuiState*: TUIState 
  tuiState.initTUIState() 

  var openingPage: Pages = login
  # var currentPage = openingPage

  case openingPage
  of login:
    tuiState.loginPageSetup()
  else:
    discard

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



