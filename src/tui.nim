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

var tb = newTerminalBuffer(terminalWidth(), terminalHeight())

tb.setForegroundColor(fgBlack, true)
tb.drawRect(0, 0, terminalWidth(), terminalHeight())
tb.drawHorizLine(2, 38, 6, doubleStyle=false)

# need to get the user handle via input, will do 
# TODO 
#also rn authenticating here as well, only once place needed, will fix all this
var client = initBlueskyClient()
client.authenticate()
let userHandle = "mebt.bsky.social"



tb.write(2, 1, fgWhite, "Press the following to perform an action: ")
tb.write(2, 2, fgWhite, "Type : ",fgGreen, "post", fgWhite, " to view all posts")
tb.write(2, 5, "Press ", fgYellow, "ESC", fgWhite,
               " or ", fgYellow, "Q", fgWhite, " to quit")

# MAIN EVENT LOOOOOOOOP
var i:int = 0
var temp_str: string = ""
while true:
  var key = getKey()
  case key
  of Key.None: discard
  of Key.Escape, Key.Q: exitProc()
  #of Key.P:
    #for i,post in posts:
        #tb.write(2,8+i,resetStyle,$key)

  else:
    tb.write(2+i,8,$key)
    i+=1
    case key
    of Key.Enter:
        tb.write(2,10,temp_str)
        case temp_str
        of "POST":
            let posts = client.getAllPostsByUser(userHandle) #moved inside so that function gets called only when input is "POST"
            for i,post in posts:
                tb.write(2,15+i,resetStyle,post["text"].getStr())
        else:
            tb.write(2,15,"HUH")
            continue
    else:
        temp_str = temp_str & $key
    #tb.write(2,10,$i)
    tb.write(2, 7, resetStyle, "What does ", fgGreen, $key, resetStyle, " do man?!")

  tb.display()
  sleep(20)
