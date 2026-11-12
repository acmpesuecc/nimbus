import illwill
import ../[tui, element]

proc loginPageSetup*(state: var TUIState) =
  state.loginRequested = false
  let x = max(1, (state.tb.width - 40) div 2)
  let y = max(2, (state.tb.height - 12) div 2)
  state.handle = InputField(x: x, y: y+3, fg: fgWhite, width: 36)
  state.password = InputField(x: x, y: y+6, fg: fgWhite, width: 36, secret: true)
  state.status = Label(x: 1, y: y+10, fg: fgYellow)
  # The event loop owns navigation; callbacks only signal an action.
  state.elements = @[
    Element(Label(x: x, y: y, fg: fgGreen, text: "NIMBUS | Sign in")),
    Element(Label(x: x, y: y+2, fg: fgWhite, text: "Handle")),
    Element(state.handle),
    Element(Label(x: x, y: y+5, fg: fgWhite, text: "App password")),
    Element(state.password),
    Element(Button(x: x, y: y+8, fg: fgWhite, text: "Sign in", width: 36)),
    Element(state.status),
    Element(Label(x: 1, y: state.tb.height-1, fg: fgWhite, text: "Tab: next field | Enter: sign in | Esc: quit"))]
  state.findFocusableElements()
  state.initFocus()
  state.update()
