noflo = require 'noflo'

class CollectObject extends noflo.Component
  description: 'Collect packets to an object identified by keys organized
  by connection'

  constructor: ->
    @keys = []
    @data = {}
    @groups = {}

    @inPorts =
      keys: new noflo.ArrayPort 'string'
      collect: new noflo.ArrayPort 'all'
      release: new noflo.Port 'bang'
      clear: new noflo.Port 'bang'
    @outPorts =
      out: new noflo.Port 'object'

    @inPorts.keys.on 'data', (key) =>
      keys = key.split ','
      if keys.length > 1
        @keys = []
      for key in keys
        @keys.push key

    @inPorts.collect.once 'connect', =>
      @subscribeSockets()

    @inPorts.release.on 'data', =>
      do @release
    @inPorts.clear.on 'data', =>
      do @clear

  release: ->
    @outPorts.out.send @data
    @outPorts.out.disconnect()
    @data = @clone @data

  subscribeSockets: ->
    # Subscribe to sockets individually
    @inPorts.collect.sockets.forEach (socket, idx) =>
      @subscribeSocket socket, idx

  subscribeSocket: (socket, id) ->
    socket.on 'begingroup', (group) =>
      unless @groups[id]
        @groups[id] = []
      @groups[id].push group
    socket.on 'data', (data) =>
      return unless @keys[id]
      groupId = @groupId @groups[id]
      unless @data[groupId]
        @data[groupId] = {}
      @data[groupId][@keys[id]] = data
    socket.on 'endgroup', =>
      return unless @groups[id]
      @groups[id].pop()

  groupId: (groups) ->
    unless groups.length
      return 'ungrouped'
    groups[0]

  clone: (data) ->
    newData = {}
    for groupName, groupedData of data
      newData[groupName] = {}
      for name, value of groupedData
        continue unless groupedData.hasOwnProperty name
        newData[groupName][name] = value
    newData

  clear: ->
    @data = {}
    @groups = {}

exports.getComponent = -> new CollectObject
