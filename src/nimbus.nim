import illwill

import ./tui/tui
import ./tui/pages/login
import ./tui/pages/mainpage



proc exitProc() {.noconv.} =
  illwillDeinit()
  showCursor()
  quit(0)

proc initTUIState*(state: var TUIState) = 
  state.tb = newTerminalBuffer(terminalWidth(), terminalHeight())
  state.elements = @[]
  state.focusableIdxs = @[]
  state.currentFocus = 0
  state.currentPage = login

when isMainModule:
  illwillInit(fullscreen=true)
  setControlCHook(exitProc)
  hideCursor()
 
  var tuiState*: TUIState 
  tuiState.initTUIState() 

  var openingPage: Pages = login
  var currentPage* = openingPage

  case currentPage
  of login:
    tuiState.loginPageSetup()
  of mainpage:
    tuiState.mainPageSetup()
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



