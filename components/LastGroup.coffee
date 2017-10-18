noflo = require 'noflo'

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Forward incoming IPs and filter groups except the last one'
  c.inPorts.add 'in',
    datatype: 'all'
    description: 'IPs to forward'
    addressable: true
  c.outPorts.add 'out',
    datatype: 'all'
  c.depth = {}
  c.tearDown = (callback) ->
    c.depth = {}
    do callback
  ensureDepth = (scope, idx) ->
    c.depth[scope] = {} unless c.depth[scope]
    return c.depth[scope][idx] if c.depth[scope][idx]
    c.depth[scope][idx] = []
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
        depth.push
          group: packet.data
          hasData: false
        return
      if packet.type is 'data'
        if depth.length
          lastLevel = depth[depth.length - 1]
          unless lastLevel.hasData
            output.send
              out: new noflo.IP 'openBracket', lastLevel.group
            lastLevel.hasData = true
        output.send
          out: packet
        return
      if packet.type is 'closeBracket'
        lastLevel = depth.pop()
        return unless lastLevel.hasData
        output.send
          out: new noflo.IP 'closeBracket', lastLevel.group
        return
    output.done()
