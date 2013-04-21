noflo = require("noflo")

class ReadGroup extends noflo.Component
  constructor: ->
    @groups = []

    @inPorts =
      in: new noflo.ArrayPort
    @outPorts =
      out: new noflo.Port

    @inPorts.in.on "begingroup", (group) =>
      @groups.push(group)

    @inPorts.in.on "disconnect", =>
      for group in @groups
        @outPorts.out.send(group)
      @outPorts.out.disconnect()

exports.getComponent = -> new ReadGroup
