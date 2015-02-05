Session = require './session'
OutputView = require './output-view'
CodeManager = require './code-manager'

module.exports =
class Controller
  constructor: (client, @workspaceView, directory) ->
    @session = new Session(client, directory)
    @codeManager = new CodeManager(workspaceView)
    @outputView = new OutputView()

  start: ->
    @workspaceView.command "nrepl:eval", =>
      @evalCurrentExpression()

  stop: ->
    @outputView.detach()
    @client?.end()

  evalCurrentExpression: ->
    expression = @codeManager.currentExpressionWithNamespace()
    if expression and expression.trim().length > 0
      endOfLine = @codeManager.endOfLastSelectedLine()
      view = @workspaceView.getActiveView()
      view.appendToLinesView(@outputView)

      pos = @workspaceView.getActiveView().pixelPositionForBufferPosition(endOfLine)
      @outputView.showSpinner(pos)

      @session.evaluate expression, (err, values) =>
        if err
          @outputView.showError(err, pos)
        else
          @outputView.showValue(values.slice(1)[0], pos)
