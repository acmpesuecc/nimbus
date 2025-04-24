import illwill
import std/strutils

import ./helpers

type 
  Element* = ref object of RootObj
    x*, y*: int
    fg*: ForegroundColor
    bg*: BackgroundColor
  
  FocusableElement* = ref object of Element
    inFocus*: bool
    
  InputField* = ref object of FocusableElement
    text*: string
    width*: int
    cursorPos*: int
    
  Heading* = ref object of Element
    text*: string
    centered*: bool
    
  Label* = ref object of Element
    text*: string
  
  Button* = ref object of FocusableElement
    text* : string
    width* : int
    height* : int
    action* : proc()


method render*(self: Element, tb: var TerminalBuffer) {.base.} = 
  tb.write(self.x, self.y, self.fg, self.bg, "")

method render*(self: Heading, tb: var TerminalBuffer) =
  let splitString = self.text.splitLines()
  var x = self.x
  var y = self.y
  
  if self.centered:
    y -= int(splitString.len / 2)
    # center around first line's length
    x -= int( countGraphemes(splitString[0]) / 2)
    
  for i, line in splitString:
    tb.write(x, y + i, self.fg, self.bg, line)

method render*(self: Label, tb: var TerminalBuffer) =
  tb.write(self.x, self.y, self.fg, self.bg, self.text)

method render*(self: InputField, tb: var TerminalBuffer) = 
  var displayText = self.text
  
  if self.inFocus:
    let cursor = "_"
    if self.cursorPos < self.text.len:
      displayText = self.text[0..<self.cursorPos] & cursor & self.text[self.cursorPos..^1]
    else:
      displayText = self.text & cursor
      
  let bg = if self.inFocus: bgBlack else: self.bg
  let padding = max(0, self.width - countGraphemes(displayText))
  tb.write(self.x, self.y, self.fg, bg, displayText & " ".repeat(padding))

method render*(self: Button, tb: var TerminalBuffer) =
  let displayText = self.text
  let padding = max(0, self.width - countGraphemes(displayText))
  let textToShow = displayText & " ".repeat(padding)
  tb.write(self.x, self.y, self.fg, self.bg, textToShow)


