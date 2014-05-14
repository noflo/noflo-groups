noflo = require "noflo"

class GroupZip extends noflo.Component
  constructor: ->
    @newGroups = []

    @inPorts = new noflo.InPorts
      in:
        datatype: 'all'
      group:
        datatype: 'string'
    @outPorts = new noflo.OutPorts
      out:
        datatype: 'all'

    @inPorts.in.on "connect", () =>
      @count = 0

    @inPorts.in.on "data", (data) =>
      @outPorts.out.beginGroup @newGroups[@count++]
      @outPorts.out.send data
      @outPorts.out.endGroup()

    @inPorts.in.on "disconnect", () =>
      @outPorts.out.disconnect()

    @inPorts.group.on "connect", =>
      @newGroups = []

    @inPorts.group.on "data", (group) =>
      @newGroups.push group

exports.getComponent = -> new GroupZip
