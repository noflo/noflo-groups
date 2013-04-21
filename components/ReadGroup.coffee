noflo = require("noflo")

class ReadGroup extends noflo.Component
  constructor: ->
    @inPorts =
      in: new noflo.ArrayPort
    @outPorts =
      out: new noflo.Port

    @inPorts.in.on "begingroup", (group) =>
      @outPorts.out.send(group)

    @inPorts.in.on "disconnect", =>
      @outPorts.out.disconnect()

exports.getComponent = -> new ReadGroup
