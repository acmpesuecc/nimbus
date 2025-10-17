import illwill, os
import ./element
import ./pages/login
import ./pages/mainpage
import ./client

type 
  Pages = enum 
    login, mainpage, settings

type 
  TUIState* = object 
    tb*: TerminalBuffer
    elements*: seq[Element]
    focusableIdxs*: seq[int]
    currentFocus*: int

proc exitProc() {.noconv.} =
  illwillDeinit()
  showCursor()
  quit(0)

proc initTUIState*(state: var TUIState) = 
  state.tb = newTerminalBuffer(terminalWidth(), terminalHeight())
  state.elements = @[]
  state.focusableIdxs = @[]
  state.currentFocus = 0

proc startTUI*(client: Client) =
  illwillInit(fullscreen=true)
  setControlCHook(exitProc)
  hideCursor()

  var tuiState: TUIState
  tuiState.initTUIState()

  var currentPage: Pages = login
  if fileExists("src/bsky/.env"):
    currentPage = mainpage

  case currentPage
  of login:
    tuiState.loginPageSetup(client)
  of mainpage:
    tuiState.mainPageSetup(client)
  else:
    discard

  tuiState.tb.display()

  while true:
    let key = getKey()
    let redraw = tuiState.handleKeyInput(key) or
                 (key == Key.Tab and tuiState.toggleFocus()) or
                 (key == Key.Down and tuiState.scrollDown()) or
                 (key == Key.Up and tuiState.scrollUp())

    if redraw:
      tuiState.update()
      tuiState.tb.display()
