import illwill
import os

import ./tui/tui
import ./tui/pages/login
import ./tui/pages/mainpage

type 
  Pages = enum 
    login, mainpage, settings

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
  var currentPage*: Pages = openingPage

  const envFilePath = "src/bsky/.env" 
  if fileExists(envFilePath):
    currentPage = mainpage

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
    of Key.Down:
      redraw = tuiState.scrollDown()
    of Key.Up:
      redraw = tuiState.scrollUp()

    else:
      redraw = tuiState.handleKeyInput(key)

    if redraw:
      tuiState.update()
      tuiState.tb.display()



