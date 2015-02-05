{View} = require 'atom'
_ = require 'underscore'

module.exports =
class OutputView extends View
  @content: ->
    @div class: 'nrepl-output', click: 'hide', =>
      @div outlet: 'value', class: 'message'

  initialize: ->
    @hide()

  showSpinner: (pos) ->
    @setPosition(pos)
    @show()
    @value.html View.render ->
      @span class: 'nrepl-spinner'

  showError: (error, pos) ->
    @setPosition(pos)
    @show()
    @value.html View.render ->
      @span class: 'text-error', error.type + " - " + error.message

  setPosition: (pos) ->
    @css left: pos.left, top: pos.top

  showValue: (value, pos) ->
    @setPosition(pos)
    @show()
    @value.html View.render ->
      @span class: 'block', value
