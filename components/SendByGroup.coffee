noflo = require 'noflo'

class SendByGroup extends noflo.Component
  description: 'Send packet held in "data" when receiving
  matching set of groups in "in"'
  icon: 'share-square'

  constructor: ->
    @data = {}
    @ungrouped = null
    @dataGroups = []
    @inGroups = []

    @inPorts = new noflo.InPorts
      in:
        datatype: 'bang'
        description: 'Signal to release IPs associated with the emitted group'
      data:
        datatype: 'all'
        description: 'IPs to store by group'
    @outPorts = new noflo.OutPorts
      out:
        datatype: 'all'
        description: 'IP associated with a group received on the in port'

    @inPorts.data.on 'begingroup', (group) =>
      @dataGroups.push group
    @inPorts.data.on 'data', (data) =>
      unless @dataGroups.length
        @ungrouped = data
        return
      @data[@groupId(@dataGroups)] = data
    @inPorts.data.on 'endgroup', =>
      @dataGroups.pop()

    @inPorts.in.on 'begingroup', (group) =>
      @inGroups.push group
    @inPorts.in.on 'data', (data) =>
      unless @inGroups.length
        @send @ungrouped if @ungrouped isnt null
        return
      id = @groupId @inGroups
      unless @data[id]
        return
      @send @data[id]
    @inPorts.in.on 'endgroup', =>
      @inGroups.pop()
    @inPorts.in.on 'disconnect', =>
      @outPorts.out.disconnect()

  groupId: (groups) ->
    groups.join ':'

  send: (data) ->
    for group in @inGroups
      @outPorts.out.beginGroup group
    @outPorts.out.send data
    for group in @inGroups
      @outPorts.out.endGroup()

exports.getComponent = -> new SendByGroup
