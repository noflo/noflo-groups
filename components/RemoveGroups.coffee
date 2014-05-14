noflo = require("noflo")

class RemoveGroups extends noflo.Component

  description: "Remove a group given a string or a regex string"

  constructor: ->
    @regexp = null

    @inPorts = new noflo.InPorts
      in:
        datatype: 'all'
        description: 'IPs to forward'
      regexp:
        datatype: 'string'
        description: 'Regexp used to remove groups'
    @outPorts = new noflo.OutPorts
      out:
        datatype: 'all'

    @inPorts.regexp.on "data", (regexp) =>
      @regexp = new RegExp(regexp)

    @inPorts.in.on "begingroup", (group) =>
      if @regexp? and not group.match(@regexp)?
        @outPorts.out.beginGroup(group)

    @inPorts.in.on "data", (data) =>
      @outPorts.out.send(data)

    @inPorts.in.on "endgroup", (group) =>
      if @regexp? and not group.match(@regexp)?
        @outPorts.out.endGroup()

    @inPorts.in.on "disconnect", =>
      @outPorts.out.disconnect()

exports.getComponent = -> new RemoveGroups
