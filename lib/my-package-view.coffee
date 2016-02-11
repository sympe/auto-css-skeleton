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
  if word.match(/^!--/)
  else
    return "noncomment"
  if word.match(/--$/)
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

#cssのブロック構造を解析
researchCssBlock = (cssFileTextSplit) ->
  continueFlag = 0
  for element,i in cssFileTextSplit
    if continueFlag > 0
      continueFlag -= 1
      continue
    if element.match(/([\s\S]*)\{[\s\S]*\}([\s\S]*)/)
      cssFileTextSplit.splice(i,1)
      elements = element.split(/\s*\{/)
      for elementd,j in elements
        if elementd.match(/[\s\S]*\}([\s\S]*)/)
          cssFileTextSplit.splice(i+j,0,RegExp.$1)
        else
          cssFileTextSplit.splice(i+j,0,elementd)
      continueFlag = elements.length-1
  return cssFileTextSplit

#bodyオブジェクトを解析して実際にcssファイルに書き込むメソッド（再帰処理）
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
    if nowkey == "body"
      stack.pop()
    if Object.keys(nowObject[nowkey]).length != 0
      researchBodyObject(nowObject[nowkey],stack,selecterArray)
    stack.pop()

getCssFileText = (cssFile) ->
  rgexp = new RegExp(/\n/gm)
  cssFileText = cssFile.getText().replace(rgexp,"")
  cssFileTextArray = cssFileText.split(/\s*\{[^}]*\}/m)
  cssFileTextArray = researchCssBlock(cssFileTextArray)
  #復帰文字を消す(for cr+lf)
  for cssText,i in cssFileTextArray
    if typeof(cssText) != "string"
      continue
    if cssText.match(/\r/)
      cssTexts = cssText.split(/\r/)
      cssFileTextArray[i] = cssTexts[cssTexts.length-1]
  return cssFileTextArray

#空行とセレクタ内部を読み飛ばす
skipSpaceAndSelecter = (cssFile) ->
  for i in [0...1000] #1つのセレクタには1000行までとする
    cssFile.selectToEndOfLine()
    line =  cssFile.getSelectedText()
    if line.match(/.*\}/)
      break
    else
      cssFile.moveDown(1)
      cssFile.moveToFirstCharacterOfLine()
  cssFile.moveDown(1) #cursorを1行下げる
  cssFile.moveToFirstCharacterOfLine()
  for i in [0...20]
    cssFile.selectToEndOfLine()
    line =  cssFile.getSelectedText()
    if line.match(/^\S/)
      cssFile.moveToFirstCharacterOfLine()
      break
    else
      cssFile.moveDown(1)
      cssFile.moveToFirstCharacterOfLine()

deleteSpaceAndSelecter = (cssFile) ->
  for i in [0...1000] #1つのセレクタには1000行までとする
    cssFile.selectToEndOfLine()
    line =  cssFile.getSelectedText()
    if line.match(/.*\}/)
      cssFile.deleteLine()
      break
    else
      cssFile.deleteLine()
      cssFile.moveToFirstCharacterOfLine()
  cssFile.moveToFirstCharacterOfLine()
  for i in [0...20]
    cssFile.selectToEndOfLine()
    line =  cssFile.getSelectedText()
    if line.match(/^\S/)
      cssFile.moveToFirstCharacterOfLine()
      break
    else
      cssFile.deleteLine()
      cssFile.moveToFirstCharacterOfLine()

#cssFileに書き込む
textEdit = (body) ->
  cssFile = atom.workspace.getActiveTextEditor()
  cssFile.moveToTop()  #cursorを一番上に
  cssFileTextArray = getCssFileText(cssFile)
  stack = []
  selecterArray = []
  researchBodyObject(body,stack,selecterArray)
  selecterArray = unique(selecterArray)
  #既にcssFileに記述されているか調べる
  for value in selecterArray
    if value in cssFileTextArray
      skipSpaceAndSelecter(cssFile)
    else
      selecterValue = value+" {}\n\n"
      cssFile.insertText(selecterValue)
  cssFile = atom.workspace.getActiveTextEditor() #もう一度cssfileを読む
  cssFile.moveToTop()
  cssFileTextArray = getCssFileText(cssFile)
  cssFile.moveToTop()
  for cssFileTextValue in cssFileTextArray
    if cssFileTextValue == ""
      continue
    if cssFileTextValue in selecterArray
      skipSpaceAndSelecter(cssFile)
    else
      deleteSpaceAndSelecter(cssFile)


module.exports =
class MyPackageView
  constructor: (serializedState) ->
    # Create root element
    @element = document.createElement('div')
    @element.classList.add('my-package')

    # Create message element
    message = document.createElement('p')
    message.textContent = "This file is not html."
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
      if line.match(/<!DOCTYPE/i) then continue
      if commentFlag == "noncomment"
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
            tagword += c
            tagFlag = true
            continue
          if tagword.match(/link.+(css)+/)
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
          if commentFlag == "commenting"
            tagword += c
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
    cssAbsolutePath = parent.path+"/"+cssFileName
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
