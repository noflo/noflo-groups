tests = require("tests/setup")

exports["if group matches, send to right, left otherwise"] = (test) ->
  [c, [ins, group, regexp], [leftOut, rightOut]] = tests.setup("MatchGroup", ["in", "group", "regexp"], ["left", "right"])
  left = []
  right = []

  test.expect(2)

  leftOut.on "data", (data) ->
    left.push(data)

  rightOut.on "data", (data) ->
    right.push(data)

  ins.on "disconnect", ->
    test.deepEqual(left, ["b"])
    test.deepEqual(right, ["a", "c"])
    test.done()

  group.send("match")
  regexp.send(/regexp/)

  ins.connect()

  ins.beginGroup("match")
  ins.send("a")
  ins.endGroup()

  ins.beginGroup("not a match")
  ins.send("b")
  ins.endGroup()

  ins.beginGroup("a regexp match")
  ins.send("c")
  ins.endGroup()

  ins.disconnect()
