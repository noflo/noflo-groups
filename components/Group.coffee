noflo = require "noflo"

class Group extends noflo.Component
  description: 'Add groups to a packet'
  constructor: ->
    @newGroups = []

    @inPorts = new noflo.InPorts
      in:
        datatype: 'all'
        description: 'IPs to forward'
      group:
        datatype: 'string'
        description: 'Groups to encapsulate incoming packets into'
      clear:
        datatype: 'bang'
        description: 'Clear encapsulating groups'
    @outPorts = new noflo.OutPorts
      out:
        datatype: 'all'
        description: 'Forwarded IPs with encapsulating groups'

    @inPorts.in.on "connect", () =>
      @outPorts.out.beginGroup group for group in @newGroups

    @inPorts.in.on "begingroup", (group) =>
      @outPorts.out.beginGroup group

    @inPorts.in.on "data", (data) =>
      @outPorts.out.send data

    @inPorts.in.on "endgroup", (group) =>
      @outPorts.out.endGroup()

    @inPorts.in.on "disconnect", () =>
      @outPorts.out.endGroup() for group in @newGroups
      @outPorts.out.disconnect()

    @inPorts.group.on "connect", =>
      @newGroups = []

    @inPorts.group.on "data", (group) =>
      groups = group.split ':'
      @newGroups.push group for group in groups

exports.getComponent = -> new Group
