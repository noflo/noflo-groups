noflo = require 'noflo'
uuid = require 'node-uuid'

class GenerateGroup extends noflo.Component

  description: 'Wrap IPs into a random uuid generated group'

  constructor: ->
    @inPorts = new noflo.InPorts
      in:
        datatype: 'all'
        description: 'IPs to forward'
    @outPorts = new noflo.OutPorts
      out:
        datatype: 'all'

    @groups = []

    @inPorts.in.on 'begingroup', (group) =>
      @beginGroup group
    @inPorts.in.on 'data', (data) =>
      @pushGeneratedGroup data
    @inPorts.in.on 'endgroup', () =>
      @popGeneratedGroup()
      @endGroup()
    @inPorts.in.on 'disconnect', () =>
      @popGeneratedGroup()
      @clearGroups()
      @outPorts.out.disconnect() if @outPorts.out.isConnected()

  beginGroup: (group) ->
    @groups.push { group: group, generated: false }
    @outPorts.out.beginGroup group if @outPorts.out.isAttached()

  endGroup: () ->
    @groups.pop()
    @outPorts.out.endGroup() if @outPorts.out.isAttached()

  pushGeneratedGroup: (data) ->
    if @groups.length < 1 or
       (@groups.length > 0 and not @groups[@groups.length - 1].generated)
      generated = { group: uuid(), generated: true }
      @groups.push generated
      @outPorts.out.beginGroup generated.group if @outPorts.out.isAttached()
    @outPorts.out.send data if @outPorts.out.isAttached()

  popGeneratedGroup: () ->
    return if @groups.length < 1
    return unless @groups[@groups.length - 1].generated
    @groups.pop()
    @outPorts.out.endGroup() if @outPorts.out.isAttached()

  clearGroups: () ->
    @groups = []

exports.getComponent = -> new GenerateGroup
