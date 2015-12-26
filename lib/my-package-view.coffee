unique = (array) ->
  storage = {}
  uniqueArray = []
  for value in array
    if !(value of storage)
      storage[value] = true
      uniqueArray.push(value)
  return uniqueArray

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
    closeTag = /<[^\/!]/
    displayText = []
    tagArr = []
    for word in words
      tagword = ""
      for c in word
        if c == "<"
          tagword += c
          tagFlag = true
        else if c == ">"
          tagword += c
          tagFlag = false
          match = tagword.match(closeTag)
          if match? then tagArr.push("#{tagword}")
          tagword = ""
        else
          if tagFlag #tagの中
            tagword += c
          #tagの外の場合は何もしない
    displayText = unique(tagArr)
    @element.children[0].textContent = displayText.join("\n")
