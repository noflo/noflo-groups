noflo = require 'noflo'

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Forward incoming IPs and filter groups except the first one'
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
    c.depth[scope][idx] = 0 unless c.depth[scope][idx]
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
        if depth is 0
          output.send
            out: new noflo.IP 'openBracket', packet.data
        c.depth[input.scope][idx]++
        return
      if packet.type is 'data'
        output.send
          out: packet
        return
      if packet.type is 'closeBracket'
        c.depth[input.scope][idx]--
        if c.depth[input.scope][idx] is 0
          output.send
            out: new noflo.IP 'closeBracket', packet.data
        return
    output.done()
