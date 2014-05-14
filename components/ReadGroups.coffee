noflo = require 'noflo'
_ = require 'underscore'

class ReadGroups extends noflo.Component
  constructor: ->
    @strip = false
    @threshold = Infinity

    @inPorts = new noflo.InPorts
      in:
        datatype: 'all'
      strip:
        datatype: 'string'
      threshold:
        datatype: 'all'
    @outPorts = new noflo.OutPorts
      out:
        datatype: 'all'
      group:
        datatype: 'string'

    @inPorts.threshold.on 'data', (threshold) =>
      @threshold = parseInt threshold
    @inPorts.strip.on 'data', (strip) =>
      @strip = strip is 'true'

    @inPorts.in.on 'connect', =>
      @count = 0
      @groups = []

    @inPorts.in.on 'begingroup', (group) =>
      beginGroup = =>
        @groups.push group
        @outPorts.out.beginGroup group if @outPorts.out.isAttached()

      # Just forward if we're past the threshold
      if @count >= @threshold
        beginGroup group

      # Otherwise send a copy to port GROUP
      else
        @outPorts.group.send group
        beginGroup group unless @strip
        @count++

    @inPorts.in.on 'endgroup', (group) =>
      if group is _.last @groups
        @groups.pop()
        @outPorts.out.endGroup() if @outPorts.out.isAttached()

    @inPorts.in.on 'data', (data) =>
      @outPorts.out.send data if @outPorts.out.isAttached()

    @inPorts.in.on 'disconnect', =>
      @outPorts.out.disconnect() if @outPorts.out.isAttached()
      @outPorts.group.disconnect()

exports.getComponent = -> new ReadGroups
