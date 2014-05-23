_ = require 'underscore'
DEFAULT_NAMESPACE = "user"

module.exports =
class CodeManager
  constructor: (@workspaceView) ->

  currentExpressionWithNamespace: ->
    editor = @workspaceView.getActiveView().editor
    range = currentExpressionRange(editor)
    unless range.isEmpty()
      expression = expressionInRange(range, editor)
    else
      expression = selectEnclosingExpression(editor, range)

    namespace = namespaceForRange(range, editor)
    [namespaceCall(namespace), expression].join("\n")

namespaceForRange = (range, editor) ->
  buffer = editor.getBuffer();
  charIndex = buffer.characterIndexForPosition(range.start)
  matches = buffer.matchesInCharacterRange(/\(ns\s+([\w\.-]+)/g, 0, charIndex)
  _.last(matches)?[1] or DEFAULT_NAMESPACE

currentExpressionRange = (editor) ->
  editor.getSelectedBufferRange()

expressionInRange = (range, editor) ->
  editor.getTextInRange(range)

namespaceCall = (namespace) ->
  "(ns #{namespace})"

selectEnclosingExpression = (editor, range) ->
  # find start of s-expression
  beforeText = editor.getTextInBufferRange([[0, 0], [range.start.row, range.start.column]])
  beforeMatch = /.*(\(.*)$/.exec beforeText

  # find end of s-expression
  afterText = editor.getTextInBufferRange([[range.start.row, range.start.column], [editor.getLastBufferRow(), null]])
  afterMatch = /^(.*?\)).*/.exec afterText

  if beforeMatch and afterMatch
    beforeMatch[0] + afterMatch[0]
