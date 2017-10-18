noflo = require 'noflo'

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Flatten group tree to a single level'
  c.inPorts.add 'in',
    datatype: 'all'
    description: 'IPs to forward'
    addressable: true
  c.outPorts.add 'out',
    datatype: 'all'
  c.depth = {}
  c.tearDown = (callback) ->
    c.depth = {}
  ensureDepth = (scope, idx) ->
    c.depth[scope] = {} unless c.depth[scope]
    return c.depth[scope][idx] if c.depth[scope][idx]
    c.depth[scope][idx] =
      groups: []
      dataGroups: []
    return c.depth[scope][idx]
  c.forwardBrackets = {}
  c.process (input, output) ->
    indexesWithIps = input.attached('in').filter (idx) ->
      input.has ['in', idx]
    return unless indexesWithIps.length
    indexesWithIps.forEach (idx) ->
      depth = ensureDepth input.scope, idx
      packet = input.get ['in', idx]
      if packet.type is 'openBracket'
        # Ignore brackets arriving after data was sent
        depth.groups.push packet.data
        return
      if packet.type is 'data'
        if depth.groups.length and not depth.dataGroups.length
          depth.dataGroups = depth.groups.slice 0
          output.send
            out: new noflo.IP 'openBracket', depth.dataGroups.join ':'
        output.send
          out: packet
        return
      if packet.type is 'closeBracket'
        if depth.groups.join(':') is depth.dataGroups.join ':'
          output.send
            out: new noflo.IP 'closeBracket', depth.dataGroups.join ':'
          depth.dataGroups = []
        depth.groups.pop()
        return
    output.done()
