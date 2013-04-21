noflo = require("noflo")

class Remove extends noflo.Component

  description: "Remove a group given a string or a regex string"

  constructor: ->
    @regexp = null
    @match = null

    @inPorts =
      in: new noflo.Port
      regexp: new noflo.Port
      group: new noflo.Port
    @outPorts =
      out: new noflo.Port

    @inPorts.regexp.on "data", (regexp) =>
      @regexp = new RegExp(regexp)

    @inPorts.group.on "data", (@group) =>

    @inPorts.in.on "begingroup", (group) =>
      unless group is @group or @regexp? and group.match(@regexp)?
        @outPorts.out.beginGroup(group)

    @inPorts.in.on "data", (data) =>
      @outPorts.out.send(data)

    @inPorts.in.on "endgroup", (group) =>
      unless group is @group or @regexp? and group.match(@regexp)?
        @outPorts.out.endGroup()

    @inPorts.in.on "disconnect", =>
      @outPorts.out.disconnect()

exports.getComponent = -> new Remove
