MyPackageView = require './my-package-view'
{CompositeDisposable} = require 'atom'

setContent = (myPackageView) ->
  editor = atom.workspace.getActiveTextEditor()
  lines = editor.getText().split(/\n/)
  myPackageView.setView(lines)

module.exports = MyPackage =
  myPackageView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    @myPackageView = new MyPackageView(state.myPackageViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @myPackageView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'my-package:toggle': => @toggle()

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @myPackageView.destroy()

  serialize: ->
    myPackageViewState: @myPackageView.serialize()

  toggle: ->

    pane = atom.workspace.getActivePaneItem()
    filename = pane.getTitle()
    #htmlファイルか調査する
    match = filename.match(/.+\.html/)
    console.log filename
    if match?
      setContent(@myPackageView)
    else
      if @modalPanel.isVisible()
        @modalPanel.hide()
      else
        @modalPanel.show()
