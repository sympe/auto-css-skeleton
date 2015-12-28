#↓使用していないメソッド
# unique = (array) ->
#   storage = {}
#   uniqueArray = []
#   for value in array
#     if !(value of storage)
#       storage[value] = true
#       uniqueArray.push(value)
#   return uniqueArray

#現在のオブジェクトの親のオブジェクトを参照するメソッド
parantObject　= (cson,stack) ->
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

  setView: (words) ->
    tagFlag = false
    commentFlag = false
    commentTag = /<!/
    cson = {}
    nowobject = cson
    stack = []
    for word in words
      match = word.match(/<!-*/)
      if match then continue
      tagword = ""
      for c in word
        if c == ">"
          tagFlag = false
          tagword += c                  #>を追加
          stackword = stack.slice(-1)
          stackword = stackword.toString().split(/\s/)
          closeTag = new RegExp("<\/"+stackword[0])
          match = tagword.match(closeTag)
          if match? #閉じタグが一番下の層と一致したら
            stack.pop() #スタックから一つ取り出す
            # console.log stack
            # console.log JSON.stringify(cson)
            nowobject = parantObject(cson,stack)  #親のオブジェクトに移動
          else  #一致しなかったら
            tagword = tagword[1..-2] #<>を切り取る
            nowobject[tagword] = {}
            nowobject = nowobject[tagword]
            stack.push(tagword)
            # console.log stack
            # console.log JSON.stringify(cson)
          tagword = ""
        else if c == "<"
          tagword += c
          tagFlag = true
        else
          if tagFlag #tagの中
            tagword += c
    console.log JSON.stringify(cson)
    @element.children[0].textContent = JSON.stringify(cson)
