#閉じタグが要らないタグ
nonCloseTag = [
  "br",
  "img",
  "hr",
  "meta",
  "input",
  "embed",
  "area",
  "base",
  "col",
  "keygen",
  "param",
  "source"
]

#配列の重複を消す
unique = (array) ->
  storage = {}
  uniqueArray = []
  for value in array
    if !(value of storage)
      storage[value] = true
      uniqueArray.push(value)
  return uniqueArray

#閉じタグが要らないタグか調べる
examNonCloseTag = (word) ->
  word = word.toString().split(/\s/)[0]
  if word in nonCloseTag
    return true
  else
    return false

#コメントタグか調べる
examCommentTag = (word) ->
  match = word.match(/^!--/)
  if match?
  else
    return "noncomment"
  match = word.match(/^!--.*--$/)
  if match?
    return "commentFin"
  else
    return "commenting"

#現在のオブジェクトの親のオブジェクトを参照するメソッド
moveParantObject　= (cson,stack) ->
  nowobject = cson
  for objName in stack
    nowobject = nowobject[objName]
  return nowobject

#headタグを走査して抜き取る
getHeadTag = (cson) ->
  runObject = cson
  if "head" of runObject
    head = Object.keys(runObject["head"])
    return head
  else
    propaties = Object.keys(runObject)
    for propaty in propaties
      return getHeadTag(runObject[propaty])

#bodyタグを走査して抜き取る
getBodyTag = (cson) ->
  runObject = cson
  if "body" of runObject
    body = { "body" : runObject["body"] }
    return body
  else
    propaties = Object.keys(runObject)
    for propaty in propaties
      return getBodyTag(runObject[propaty])

getCssFileName = (head) ->
  cssFileName = "example.css"
  for item in head
    if item.match(/link.+css.+/)
      if item.match(/href=\"(\S+\.css)\"/)
        cssFileName = RegExp.$1
        return cssFileName
  return cssFileName

#cssFileに書き込む
textEdit = (body) ->
  cssFile = atom.workspace.getActiveTextEditor()
  cssFile.moveToTop()  #cursorを一番上に
  rgexp = new RegExp(/^\n/gm)
  cssFileText = cssFile.getText().replace(rgexp,"")
  cssFileTextSplit = cssFileText.split(/\s{}/)
  stack = []
  selecterArray = []
  researchBodyObject(body,stack,selecterArray)
  selecterArray = unique(selecterArray)
  # console.log selecterArray
  for value in selecterArray
    reg = new RegExp(value)
    matchFlag = false
    for cssFileTextSplitValue in cssFileTextSplit
      if cssFileTextSplitValue.match(reg)
        matchFlag = true
        cssFile.moveDown(2) #cursorを2行下げるマジックナンバーだorz
        break
    if !matchFlag
      selecterValue = value+" {}\n\n"
      cssFile.insertText(selecterValue)
  # console.log cssFile.getCursorBufferPosition()

#オブジェクトを解析して実際に書き込むcssファイルに書き込むメソッド
researchBodyObject = (nowObject,stack,selecterArray) ->
  nowObjectKeys = Object.keys(nowObject)
  for nowkey in nowObjectKeys
    if nowkey.match(/(.+)\sid=\"(.+)\"/)
      cssStr = RegExp.$1+"\#"+RegExp.$2
    else if nowkey.match(/(.+)\sclass=\"(.+)\"/)
      className = RegExp.$1
      classes = RegExp.$2.split(/\s/)
      for cls in classes
        cssStr = className+"\."+cls
        stack.push(cssStr)
        str = stack.join(" ")
        selecterArray.push(str)
        if Object.keys(nowObject[nowkey]).length != 0
          researchBodyObject(nowObject[nowkey],stack,selecterArray)
        stack.pop()
      continue
    else if nowkey.match(/a\s.+=.+/)
      cssStr = "a"
    else
      cssStr = nowkey
    stack.push(cssStr)
    str = stack.join(" ")
    selecterArray.push(str)
    #bodyは即pop
    if nowkey == "body"
      stack.pop()
    if Object.keys(nowObject[nowkey]).length != 0
      researchBodyObject(nowObject[nowkey],stack,selecterArray)
    stack.pop()

module.exports =
class MyPackageView
  constructor: (serializedState) ->
    # Create root element
    @element = document.createElement('div')
    @element.classList.add('my-package')

    # Create message element
    message = document.createElement('p')
    message.textContent = "htmlファイルではありません"
    message.classList.add('message')
    @element.appendChild(message)

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @element.remove()

  getElement: ->
    @element

  openCssFile: (lines) ->
    tagFlag = false
    cson = {}
    stack = []
    commentFlag = "noncomment"
    nowobject = cson
    for line in lines
      if line.match(/<!DOCTYPE/i) then continue #ドキュメントタイプ宣言とばす
      tagword = ""
      for c in line
        if c == ">"
          tagFlag = false
          if examNonCloseTag(tagword)
            tagword = ""
            continue
          commentFlag = examCommentTag(tagword)
          if commentFlag == "commentFin"
            tagword = ""
            continue
          else if commentFlag == "commenting"
            continue
          if tagword.match(/link.+(css)+/) #cssタグだったら
            nowobject[tagword] = {}
            tagword = ""
            continue
          stackword = stack.slice(-1)
          stackword = stackword.toString().split(/\s/)[0]
          closeTag = new RegExp("\/"+stackword)
          if tagword.match(closeTag) #閉じタグが一番下の層と一致したら
            stack.pop() #スタックから一つ取り出す
            nowobject = moveParantObject(cson,stack)  #親のオブジェクトに移動
          else  #一致しなかったら
            nowobject[tagword] = {}
            nowobject = nowobject[tagword]
            stack.push(tagword)
          tagword = ""
        else if c == "<"
          tagFlag = true
        else
          if tagFlag #tagの中
            tagword += c

    #headとbodyをhtmlから取得
    head = getHeadTag(cson)
    body = getBodyTag(cson)
    #paneから現在開いているテキストエディタのpathを取得
    pane = atom.workspace.getActivePaneItem()
    path = pane.getPath()
    #fileインスタンスを一つつくってpathを設定する
    project = atom.project
    directory = project.getDirectories()[0]
    file = directory.getFile()
    file.path = path
    parent = file.getParent()
    cssFileName = getCssFileName(head)
    cssAbsolutePath = parent.path+"\\"+cssFileName
    #cssファイルを開く
    atom.workspace.open(cssAbsolutePath)
    timer = setInterval ->
      pane = atom.workspace.getActivePaneItem()
      filename = pane.getTitle()
      match = filename.match(/.+\.css/)
      if match?
        textEdit(body)
        clearInterval(timer)
    , 300
