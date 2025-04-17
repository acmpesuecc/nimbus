import os, strutils, json
import illwill
import nimbus

proc exitProc() {.noconv.} =
  illwillDeinit()
  showCursor()
  quit(0)

illwillInit(fullscreen=true)
setControlCHook(exitProc)
hideCursor()

var logo: string = """
███╗░░██╗██╗███╗░░░███╗██████╗░██╗░░░██╗░██████╗
████╗░██║██║████╗░████║██╔══██╗██║░░░██║██╔════╝
██╔██╗██║██║██╔████╔██║██████╦╝██║░░░██║╚█████╗░
██║╚████║██║██║╚██╔╝██║██╔══██╗██║░░░██║░╚═══██╗
██║░╚███║██║██║░╚═╝░██║██████╦╝╚██████╔╝██████╔╝
╚═╝░░╚══╝╚═╝╚═╝░░░░░╚═╝╚═════╝░░╚═════╝░╚═════╝░
"""

var tb = newTerminalBuffer(terminalWidth(), terminalHeight())

proc LandingScreen(): void = 
  tb.setForegroundColor(fgBlack, true)
  tb.drawRect(0, 0, terminalWidth(), terminalHeight())
  tb.drawHorizLine(2, 50, 9, doubleStyle=true)

proc InputBox(): void =
  for column in 2..terminalWidth():
      tb.write(column,19," ")

  tb.drawRect(2,17,35,21)
  tb.write(2,17," Spotlight Commands ")

proc clearRow(tb: var TerminalBuffer, row: int, till_end : bool = false ): void =
  var RowToClearTill : int = row
  if till_end == true:
    RowToClearTill = terminalHeight()-1
  tb.display()

  for row in row..RowToClearTill:
    for column in 1..terminalWidth()-1:
      tb.write(column, row, " ") 


# need to get the user handle via input, will do 
# TODO 
#also rn authenticating here as well, only once place needed, will fix all this
var client = initBlueskyClient()
client.authenticate()
let userHandle = "mebt.bsky.social"

#below code splits the logo which is a multiline into single lines
#then prints these one by one
var SplitOfLogo: seq[string] = logo.split("\n")
for i,line in SplitOfLogo:
  tb.write(2,2+i, fgWhite, line)

tb.write(2, 11, fgWhite, "Press the following to perform an action: ")
tb.write(2, 12, fgWhite, "Type : ",fgGreen, "post", fgWhite, " to view all posts")
tb.write(2, 15, "Press ", fgYellow, "ESC", fgWhite,
               " or ", fgYellow, "Q", fgWhite, " to quit")


# MAIN EVENT LOOOOOOOOP

var i:int = 0
var temp_str: string = ""
LandingScreen()
InputBox()

while true:
  var key = getKey()
  case key
  of Key.None: discard
  of Key.Escape, Key.Q: exitProc()
  of Key.Enter:
          clearRow(tb,22, till_end = true) #clearing input box everytime
          InputBox() #re-initilize input box, clearing previous contents
          tb.write(4,19,temp_str)
          case temp_str
          of "POST":
              tb.write(2,22,fgGreen,"Fetching posts...")
              tb.display() #this is required the flush the buffer, else it doesn't seem to do it automatically

              let posts = client.getAllPostsByUser(userHandle) #moved inside so that function gets called only when input is "POST"
              clearRow(tb,22) #clear the 'fetching posts...' on line 22 first
              tb.write(2,22,fgGreen,"Your posts:")
              for i,post in posts:
                  tb.write(2,25+i,resetStyle,post["text"].getStr())
              
              InputBox() #clearning row with temp typed string
              temp_str = "" #clearing temp_string again cause entered pressed
              i = 0 #resetting cursor position
              continue
          else:
              clearRow(tb,25,till_end = true)
              tb.write(2,23,"What man? I don't understand that command ")
              temp_str = "" #clearing temp_string again cause entered pressed
              i = 0 #resetting cursor position
              InputBox()
              continue

  else:

    tb.write(4+i,19,$key)
    i+=1
    temp_str = temp_str & $key #append character to temp_string if key pressed is not enter

  tb.display()
  sleep(20)
