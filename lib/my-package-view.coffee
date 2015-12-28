#↓使用していないメソッド
# unique = (array) ->
#   storage = {}
#   uniqueArray = []
#   for value in array
#     if !(value of storage)
#       storage[value] = true
#       uniqueArray.push(value)
#   return uniqueArray

#閉じタグが要らないタグ
nonCloseTag = [
  "br",
  "img",
  "meta",
  "input",
  "embed",
  "area",
  "base",
  "col",
  "keygen",
  "link",
  "param",
  "source"
]

#閉じタグが要らないタグか調べる
examNonCloseTag = (word) ->
  word = word.toString().split(/\s/)[0]
  if word in nonCloseTag
    return true
  else
    return false

#現在のオブジェクトの親のオブジェクトを参照するメソッド
moveParantObject　= (cson,stack) ->
  nowobject = cson
  for objName in stack
    nowobject = nowobject[objName]
  return nowobject

module.exports =
class MyPackageView
  constructor: (serializedState) ->
    # Create root element
    @element = document.createElement('div')
    @element.classList.add('my-package')

    # Create message element
    message = document.createElement('pre')
    message.textContent = "The MyPackage package is Alive! It's ALIVE!"
    message.classList.add('message')
    @element.appendChild(message)

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @element.remove()

  getElement: ->
    @element

  setView: (lines) ->
    tagFlag = false
    cson = {}
    nowobject = cson
    stack = []
    for line in lines
      match = line.match(/<!-*/)
      if match? then continue
      tagword = ""
      for c in line
        if c == ">"
          tagFlag = false
          if examNonCloseTag(tagword) then continue #閉じタグか調査する
          stackword = stack.slice(-1)
          stackword = stackword.toString().split(/\s/)[0]
          closeTag = new RegExp("\/"+stackword)
          match = tagword.match(closeTag)
          if match? #閉じタグが一番下の層と一致したら
            stack.pop() #スタックから一つ取り出す
            # console.log stack
            # console.log JSON.stringify(cson)
            nowobject = moveParantObject(cson,stack)  #親のオブジェクトに移動
          else  #一致しなかったら
            nowobject[tagword] = {}
            nowobject = nowobject[tagword]
            stack.push(tagword)
            # console.log stack
            # console.log JSON.stringify(cson)
          tagword = ""
        else if c == "<"
          tagFlag = true
        else
          if tagFlag #tagの中
            tagword += c
    console.log JSON.stringify(cson)
    @element.children[0].textContent = JSON.stringify(cson)
