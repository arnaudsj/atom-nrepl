{Range} = require 'atom'
_ = require 'underscore'
DEFAULT_NAMESPACE = "user"

module.exports =
class CodeManager
  constructor: (@workspaceView) ->

  currentExpressionWithNamespace: ->
    editor = @workspaceView.getActiveView().editor
    range = currentExpressionRange(editor)

    # If no text is selected we find the enclosing s-expression
    if range.isEmpty()
      # If we're at the start or end of the line we move inwards to find the
      # enclosing s-expression
      if startOfLine(range.start, editor)
        range = new Range([range.start.row, 1], [range.start.row, 1])
      else if endOfLine(range.end, editor)
        range = new Range([range.start.row, range.end.column - 1], [range.start.row, range.end.column - 1])

      range = selectEnclosingExpression(editor, range)

    return unless range

    expression = expressionInRange(range, editor)

    namespace = namespaceForRange(range, editor)
    [namespaceCall(namespace), expression].join("\n")

  endOfLastSelectedLine: ->
    editor = @workspaceView.getActiveView().editor
    range = currentExpressionRange(editor)
    row = if range.end.column == 0 then range.end.row - 1 else range.end.row
    column = lineLength(row, editor)

    [row, column]


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

startOfLine = (point, editor) ->
  point.column == 0

endOfLine = (point, editor) ->
  lineLength(point.row, editor) == point.column

lineLength = (row, editor) ->
  editor.lineLengthForBufferRow(row)

findStartOfExpression = (cursor, editor) ->
  endBrackets = 0
  expressionStart = null
  beforeRange = [[0, 0], [cursor.start.row, cursor.start.column]]
  editor.getBuffer().backwardsScanInRange /[\(\)]/g, beforeRange, ({match, range, stop}) ->
    switch match[0]
      when ")" then endBrackets++
      when "("
        if endBrackets == 0
          expressionStart = range.start
          stop()
        else
          endBrackets--
  expressionStart

findEndOfExpression = (cursor, editor) ->
  startBrackets = 0
  expressionEnd = null
  buffer = editor.getBuffer()
  afterRange = [[cursor.start.row, cursor.start.column],
                [editor.getLastBufferRow(), buffer.getLastLine().length]]
  buffer.scanInRange /[\(\)]/g, afterRange, ({match, range, stop}) ->
    switch match[0]
      when "(" then startBrackets++
      when ")"
        if startBrackets == 0
          expressionEnd = range.end
          stop()
        else
          startBrackets--
  expressionEnd

selectEnclosingExpression = (editor, range) ->
  # find start of s-expression
  expressionStart = findStartOfExpression(range, editor)

  # find end of s-expression
  expressionEnd = findEndOfExpression(range, editor)

  if expressionStart and expressionEnd
    # highlight text
    expressionRange = new Range(expressionStart, expressionEnd)
    editor.setSelectedBufferRange(expressionRange)
    expressionRange
