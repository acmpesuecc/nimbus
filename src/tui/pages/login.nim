import illwill
import ./../element
import ./../helpers
import ./../client
import ./mainpage

const nimbusLogo = """<your logo here>"""

proc loginPageSetup*(state: var TUIState, client: Client) =
  let center = findCenter(terminalWidth(), terminalHeight())

  proc mainpageRoute(client: Client) =
    var tuiState: TUIState
    tuiState.initTUIState()
    tuiState.mainPageSetup(client)
    tuiState.tb.display()

    while true:
      let key = getKey()
      let redraw = tuiState.handleKeyInput(key) or
                   (key == Key.Tab and tuiState.toggleFocus())

      if redraw:
        tuiState.update()
        tuiState.tb.display()

  proc writeToEnv(Handle, Password: InputField) =
    let PDSHOST = "PDSHOST=https://bsky.social\n"
    let BLUESKY_HANDLE = "BLUESKY_HANDLE=" & Handle.text & "\n"
    let APP_PASSWORD = "APP_PASSWORD=" & Password.text & "\n"

    writeFile(".env", PDSHOST & BLUESKY_HANDLE & APP_PASSWORD)
    writeFile("src/bsky/.env", PDSHOST & BLUESKY_HANDLE & APP_PASSWORD)

    mainpageRoute(client)

  var BLUESKY_HANDLE = InputField(x: center.x - 11, y: center.y, fg: fgWhite, bg: bgBlack, inFocus: false, width: 30, text: "", cursorPos: 0)
  var APP_PASSWORD = InputField(x: center.x - 11, y: center.y + 3, fg: fgWhite, bg: bgBlack, inFocus: false, width: 30, text: "", cursorPos: 0)

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
