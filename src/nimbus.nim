import illwill
import std/[os, strutils]
import dotenv
import ./tui/[tui, element]
import ./tui/pages/[login, mainpage]
import ./bsky/bsky

proc run() =
  illwillInit(fullscreen = true)
  hideCursor()
  try:
    var state = TUIState(tb: newTerminalBuffer(terminalWidth(), terminalHeight()))
    var client: BlueskyClient
    var loggedIn = false
    var startupError = ""
    if fileExists(".env"):
      state.elements = @[Element(Label(x: 1, y: 1, fg: fgGreen, text: "NIMBUS | Signing in..."))]
      state.update()
      state.tb.display()
      try:
        load()
        client = initBlueskyClient()
        client.authenticate()
        loggedIn = true
        state.mainPageSetup(client)
      except CatchableError:
        startupError = "Saved sign-in failed. Check credentials and connection; retry."
    if not loggedIn:
      state.loginPageSetup()
      state.handle.text = getEnv("BLUESKY_HANDLE")
      state.handle.cursorPos = state.handle.text.len
      state.status.text = startupError
    state.update()
    state.tb.display()
    while true:
      let key = getKey()
      sleep(20)
      if key in {Key.Escape, Key.CtrlC}: break
      if state.tb.width != terminalWidth() or state.tb.height != terminalHeight():
        state.tb = newTerminalBuffer(terminalWidth(), terminalHeight())
        if loggedIn:
          state.mainPageSetup(client)
        else:
          let handle = state.handle.text
          let password = state.password.text
          state.loginPageSetup()
          state.handle.text = handle
          state.handle.cursorPos = handle.len
          state.password.text = password
          state.password.cursorPos = password.len
      if not loggedIn:
        case key
        of Key.Tab: discard state.toggleFocus()
        of Key.Enter:
          state.status.text = "Signing in..."
          state.update()
          state.tb.display()
          try:
            client = initBlueskyClient(state.handle.text.strip(), state.password.text.strip())
            client.authenticate()
            loggedIn = true
            state.password.text = ""
            var notice = ""
            try:
              client.saveCredentials()
            except CatchableError:
              notice = "Signed in, but could not save .env. Sign in again on next launch."
            state.mainPageSetup(client, notice = notice)
          except CatchableError:
            state.status.text = "Sign-in failed. Check credentials and connection; retry."
        else: discard state.handleKeyInput(key)
      else:
        case key
        of Key.L, Key.ShiftL:
          loggedIn = false
          state.loginPageSetup()
        of Key.R, Key.ShiftR: state.mainPageSetup(client, refreshing = true)
        of Key.Down:
          if state.elements.len > 0 and state.elements[^1].y >= state.tb.height:
            discard state.scrollDown()
        of Key.Up:
          if state.elements.len > 0 and state.elements[0].y < 0:
            discard state.scrollUp()
        else: discard
      if key != Key.None:
        state.update()
      state.tb.display()
  finally:
    illwillDeinit()
    showCursor()

when isMainModule:
  run()
