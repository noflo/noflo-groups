noflo = require 'noflo'

class LastGroup extends noflo.Component
  description: 'Forward packets wrapped only using the latest emitted
  group'
  constructor: ->
    @inPorts = new noflo.InPorts
      in:
        datatype: 'all'
        description: 'IPs to forward'
    @outPorts = new noflo.OutPorts
      out:
        datatype: 'all'

    @groups = []
    @groupSent = 0

    @inPorts.in.on 'begingroup', (group) =>
      @storeGroup group
    @inPorts.in.on 'data', (data) =>
      @sendBeginGroup()
      @outPorts.out.send data if @outPorts.out.isAttached()
    @inPorts.in.on 'endgroup', (group) =>
      @sendEndGroup()
    @inPorts.in.on 'disconnect', =>
      @outPorts.out.disconnect() if @outPorts.out.isConnected()

  storeGroup: (group) ->
    @groups.push { name: group, emitted: false }

  sendBeginGroup: () ->
    return unless @groups.length > 0
    group = @groups[@groups.length - 1]
    return if group.emitted
    group.emitted = true
    @outPorts.out.beginGroup group.name if @outPorts.out.isAttached()

  sendEndGroup: () ->
    group = @groups.pop()
    return unless group.emitted
    @outPorts.out.endGroup() if @outPorts.out.isAttached()

  clearGroups: () ->
    @groups = []

exports.getComponent = -> new LastGroup
