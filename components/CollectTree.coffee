noflo = require 'noflo'

class CollectTree extends noflo.Component
  description: 'Collect grouped packets into a simple tree structure
  and send on disconnect'

  constructor: ->
    @data = null
    @collectGroups = []
    @forwardGroups = []
    @level = 0
    @inPorts = new noflo.InPorts
      in:
        datatype: 'all'
      level:
        datatype: 'integer'
        default: 0
        description: 'Number of groups (from outermost) to skip collection of'
    @outPorts = new noflo.OutPorts
      out:
        datatype: 'all'
      error:
        datatype: 'object'

    @inPorts.level.on 'data', (data) =>
      @level = data

    @inPorts.in.on 'connect', =>
      @data = {}
    @inPorts.in.on 'begingroup', (group) =>
      if @forwardGroups.length < @level
        @forwardGroups.push group
      else
        @collectGroups.push group
    @inPorts.in.on 'data', (data) =>
      return unless @collectGroups.length
      d = @data
      for g, idx in @collectGroups
        if idx < @collectGroups.length - 1
          d[g] = {} unless d[g]
          d = d[g]
          continue
      unless d[g]
        d[g] = data
        return
      unless Array.isArray d[g]
        d[g] = [d[g]]
      d[g].push data
    @inPorts.in.on 'endgroup', =>
      if @forwardGroups.length < @level
        # will be sent & reset on disconnect
      else
        @collectGroups.pop()
    @inPorts.in.on 'disconnect', =>
      @collectGroups = []
      if Object.keys(@data).length

        for group in @forwardGroups
          @outPorts.out.beginGroup group
        @outPorts.out.send @data
        for group in @forwardGroups
          @outPorts.out.endGroup()
        @outPorts.out.disconnect()
        @forwardGroups = []
        @data = null
        return

      @data = null
      err = new Error 'No tree information was collected'
      if @outPorts.error.isAttached()
        @outPorts.error.send err
        @outPorts.error.disconnect()
        return
      throw err

exports.getComponent = -> new CollectTree
