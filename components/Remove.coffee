noflo = require("noflo")

class Remove extends noflo.Component

  description: "Remove a group given a string or a regex string"

  constructor: ->
    @regexp = null

    @inPorts =
      in: new noflo.Port
      group: new noflo.Port
    @outPorts =
      out: new noflo.Port

    @inPorts.group.on "data", (regexp) =>
      @regexp = new RegExp(regexp)

    @inPorts.in.on "begingroup", (group) =>
      unless @regexp? and group.match(@regexp)?
        @outPorts.out.beginGroup(group)

    @inPorts.in.on "data", (data) =>
      @outPorts.out.send(data)

    @inPorts.in.on "endgroup", (group) =>
      unless @regexp? and group.match(@regexp)?
        @outPorts.out.endGroup()

    @inPorts.in.on "disconnect", =>
      @outPorts.out.disconnect()

exports.getComponent = -> new Remove
