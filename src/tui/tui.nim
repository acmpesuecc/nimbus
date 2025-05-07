import illwill

import ./element

# maybe this could be global instead of passing state everywhere, 
type 
  TUIState* = object 
    tb*: TerminalBuffer
    elements*: seq[Element]
    focusableIdxs*: seq[int]
    currentFocus*: int

proc update*(state: var TUIState) =
  #first remove all elements from the terminal buffer
  state.tb.clear()
  for elem in state.elements:
    # -_-feels weird to call elem.render instead of tb.render, have to look into this
    # can switch to proc's but then no dynamic dispatch
    # also massive room for optimization
    for i in 0 .. terminalWidth():
      state.tb.write(i, elem.y, " ")
    elem.render(state.tb)  

method handleInput*(self: FocusableElement, key: Key): bool {.base.} =
  return false

method handleInput*(self: InputField, key: Key): bool =
  if not self.inFocus:
    return false

  result = true

  case key
  of Key.Backspace:
    if self.cursorPos > 0:
      self.text = self.text[0..<self.cursorPos-1] & self.text[self.cursorPos..^1]
      self.cursorPos -= 1
  of Key.Left:
    if self.cursorPos > 0:
      self.cursorPos -= 1
  of Key.Right:
    if self.cursorPos < self.text.len:
      self.cursorPos += 1
  else:
    let ch = char(key)
    if ord(ch) >= 33 and ord(ch) <= 126:
      self.text = self.text[0..<self.cursorPos] & ch & self.text[self.cursorPos..^1]
      self.cursorPos += 1
    else:
      result = false

method handleInput*(self: Button, key: Key): bool =
  if not self.inFocus:
    return false

  if key == Key.Enter:
    if self.action != nil:
      self.action()
    return true
  return false

proc handleKeyInput*(state: TUIState, key: Key): bool =
  for elem in state.elements:
    if elem of FocusableElement:
      let focusable = FocusableElement(elem)
      if focusable.handleInput(key):
        return true
  return false

proc findFocusableElements*(state: var TUIState) =
  for i, elem in state.elements:
    if elem of FocusableElement:
      state.focusableIdxs.add(i)

proc scrollDown*(state: var TUIState): bool =
  if state.elements.len != 0: 
    #state.elements = state.elements[1..^1]

    for element in state.elements:
      if element.y-1 < 0:
        element.y = 0
      else:
        element.y -= 1
      state.update()
    return true
  return false

proc scrollUp*(state: var TUIState): bool =
  if state.elements.len != 0: 
    # Move all elements up by 1 line
    for elem in state.elements:
      elem.y += 1
    state.update()
    return true
  return false

proc initFocus*(state: var TUIState) =
  if state.focusableIdxs.len == 0: return

  let focusableIdxs = state.focusableIdxs
  let currentFocus = state.currentFocus

  FocusableElement(state.elements[focusableIdxs[currentFocus]]).inFocus = true

proc toggleFocus*(state: var TUIState): bool =
  let focusableIdxs = state.focusableIdxs
  var currentFocus = state.currentFocus

  if focusableIdxs.len > 1:
    FocusableElement(state.elements[focusableIdxs[currentFocus]]).inFocus = false
    
    currentFocus = (currentFocus + 1) mod focusableIdxs.len
    state.currentFocus = currentFocus

    FocusableElement(state.elements[focusableIdxs[currentFocus]]).inFocus = true
    
    return true

  return false
