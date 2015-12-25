MyPackageView = require './my-package-view'
{CompositeDisposable} = require 'atom'

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
    console.log 'MyPackage was toggled!'

    if @modalPanel.isVisible()
      @modalPanel.hide()
    else
      @modalPanel.show()
