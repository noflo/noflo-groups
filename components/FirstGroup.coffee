noflo = require 'noflo'

class FirstGroup extends noflo.Component
  description: 'Forward incoming IPs and filter groups except the first one'
  constructor: ->
    @depth = 0

    @inPorts = new noflo.InPorts
      in:
        datatype: 'all'
        description: 'IPs to forward'
    @outPorts = new noflo.OutPorts
      out:
        datatype: 'all'

    @inPorts.in.on 'begingroup', (group) =>
      @outPorts.out.beginGroup group if @depth is 0
      @depth++

    @inPorts.in.on 'data', (data) =>
      @outPorts.out.send data

    @inPorts.in.on 'endgroup', (group) =>
      @depth--
      @outPorts.out.endGroup() if @depth is 0

    @inPorts.in.on 'disconnect', =>
      @depth = 0
      @outPorts.out.disconnect()

exports.getComponent = -> new FirstGroup
