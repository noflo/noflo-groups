noflo = require 'noflo'

class CollectTree extends noflo.Component
  description: 'Collect grouped packets into a simple tree structure
  and send on disconnect'

  constructor: ->
    @data = null
    @groups = []
    @inPorts =
      in: new noflo.Port 'all'
    @outPorts =
      out: new noflo.Port 'all'
      error: new noflo.Port 'object'

    @inPorts.in.on 'connect', =>
      @data = {}
    @inPorts.in.on 'begingroup', (group) =>
      @groups.push group
    @inPorts.in.on 'data', (data) =>
      return unless @groups.length
      d = @data
      for g, idx in @groups
        if idx < @groups.length - 1
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
      @groups.pop()
    @inPorts.in.on 'disconnect', =>
      @groups = []
      if Object.keys(@data).length
        @outPorts.out.send @data
        @outPorts.out.disconnect()
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
