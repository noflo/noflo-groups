noflo = require 'noflo'

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Send the groups surrounding a packet'
  c.inPorts.add 'in',
    datatype: 'all'
    addressable: true
  c.outPorts.add 'out',
    datatype: 'all'
  c.outPorts.add 'group',
    datatype: 'string'
  c.groups = {}
  ensureGroups = (scope, idx) ->
    c.groups[scope] = {} unless c.groups[scope]
    c.groups[scope][idx] = [] unless c.groups[scope][idx]
    return c.groups[scope][idx]
  c.tearDown = (callback) ->
    c.groups = {}
    do callback
  c.forwardBrackets = {}
  c.process (input, output) ->
    indexesWithIps = input.attached('in').filter (idx) ->
      input.has ['in', idx]
    return unless indexesWithIps.length
    indexesWithIps.forEach (idx) ->
      groups = ensureGroups input.scope, idx
      packet = input.get ['in', idx]
      if packet.type is 'openBracket'
        groups.push packet.data
        output.send
          out: packet
          group: packet
        return
      if packet.type is 'data'
        output.send
          group: groups.join ':'
        output.send
          out: packet
        return
      if packet.type is 'closeBracket'
        groups.pop()
        output.send
          out: packet
          group: packet
        return
    output.done()
