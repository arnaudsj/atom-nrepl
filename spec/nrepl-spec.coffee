{WorkspaceView, EditorView, Range, Point} = require 'atom'
{Directory} = require 'pathwatcher'
fs = require 'fs'
temp = require 'temp'
FakeNreplClient = require './helpers/fake-nrepl-client'
Controller = require '../lib/controller'

describe "nrepl", ->
  [client, directory, controller, workspaceView, editorView] = []

  beforeEach ->
    waitsFor (done) ->
      setUpFakeProjectDir (path) ->
        client = new FakeNreplClient()
        directory = new Directory(path)
        workspaceView = new WorkspaceView
        editorView = setUpActiveEditorView(workspaceView)
        editorView.insertText("""
          (ns the-first.namespace
            (require [some-library]))
          (the first expression)
          (the second expression)

          (ns the-second.namespace
            (use [some-other-library]))
          (the third expression)
          """)
        controller = new Controller(client, workspaceView, directory)
        controller.start()
        done()

  describe "when a REPL is running", ->
    fakePort = 41235

    beforeEach ->
      waitsFor (done) ->
        setUpFakePortFile(directory.path, fakePort, done)

    describe "an expression is selected", ->
      beforeEach ->
        runs ->
          spyOn(editorView.editor, 'getSelectedBufferRange').andReturn(new Range([3, 0], [4, 0]))
          workspaceView.trigger('nrepl:eval')
        waits 5

      it "displays the value of selected expression, evaluated in the right namespace", ->
        client.simulateConnectionSucceeding()
        client.simulateEvaluationSucceeding(
          """
          (ns the-first.namespace)
          (the second expression)\n
          """,
          ["nil", ":the-first-value"])

        outputView = editorView.find(".nrepl-output:first")
        expect(outputView.eq(0).text()).toBe(":the-first-value")

    describe "nothing is selected", ->
      beforeEach ->
        runs ->
          spyOn(editorView.editor, 'getSelectedBufferRange').andReturn(new Range([2, 3], [2, 3]))
          workspaceView.trigger('nrepl:eval')
        waits 5

      it "selects the enclosing expression", ->
        client.simulateConnectionSucceeding()
        client.simulateEvaluationSucceeding(
          """
          (ns the-first.namespace)
          (the first expression)
          """,
          ["nil", ":the-first-value"])

        outputView = editorView.find(".nrepl-output:first")
        expect(outputView.eq(0).text()).toBe(":the-first-value")

    describe "the cursor is at the beginning of a line", ->
      beforeEach ->
        runs ->
          spyOn(editorView.editor, 'getSelectedBufferRange').andReturn(new Range([3, 0], [3, 0]))
          workspaceView.trigger('nrepl:eval')
        waits 5

      it "selects the expression that starts on that line", ->
        client.simulateConnectionSucceeding()
        client.simulateEvaluationSucceeding(
          """
          (ns the-first.namespace)
          (the second expression)
          """,
          ["nil", ":the-first-value"])

        outputView = editorView.find(".nrepl-output:first")
        expect(outputView.eq(0).text()).toBe(":the-first-value")

    describe "the cursor is at the end of a line", ->
      beforeEach ->
        runs ->
          spyOn(editorView.editor, 'getSelectedBufferRange').andReturn(new Range([3, 23], [3, 23]))
          workspaceView.trigger('nrepl:eval')
        waits 5

      it "selects the expression that ends on that line", ->
        client.simulateConnectionSucceeding()
        client.simulateEvaluationSucceeding(
          """
          (ns the-first.namespace)
          (the second expression)
          """,
          ["nil", ":the-first-value"])

        outputView = editorView.find(".nrepl-output:first")
        expect(outputView.eq(0).text()).toBe(":the-first-value")

# helpers

setUpActiveEditorView = (parent) ->
  result = new EditorView(mini: true)
  spyOn(parent, 'getActiveView').andReturn(result)
  result

setUpFakeProjectDir = (f) ->
  temp.mkdir("atom-nrepl-test", (err, path) -> f(path))

setUpFakePortFile = (path, port, f) ->
  fs.mkdir "#{path}/target", ->
    fs.writeFile("#{path}/target/repl-port", port.toString(), f)
