import unicode

type 
  Point* = tuple 
    x, y: int 

proc findCenter*(width, height: int): Point =
  result = (x: int( width / 2), y: int(height / 2) )

proc countGraphemes*(text: string): int = 
  var currentIdx = 0
  while currentIdx < text.len:
    result += 1
    currentIdx += text.graphemeLen(currentIdx)
