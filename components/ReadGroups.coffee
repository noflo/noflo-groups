noflo = require 'noflo'

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Send the groups surrounding a packet'
  c.inPorts.add 'in',
    datatype: 'all'
    addressable: true
  c.inPorts.add 'strip',
    datatype: 'boolean'
    control: true
    default: false
  c.inPorts.add 'threshold',
    datatype: 'int'
    control: true
    default: Infinity
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
    return if input.attached('strip').length and not input.hasData('strip')
    return if input.attached('threshold').length and not input.hasData('threshold')
    if input.hasData 'strip'
      strip = String(input.getData('strip')) is 'true'
    else
      strip = false
    if input.hasData 'threshold'
      threshold = parseInt(input.getData('threshold'))
    else
      threshold = Infinity
    indexesWithIps.forEach (idx) ->
      groups = ensureGroups input.scope, idx
      packet = input.get ['in', idx]
      if packet.type is 'openBracket'
        groups.push packet.data
        if groups.length > threshold
          output.send
            out: packet
          return
        output.send
          group: packet.data
        return if strip
        output.send
          out: packet
        return
      if packet.type is 'data'
        output.send
          out: packet
        return
      if packet.type is 'closeBracket'
        if groups.length > threshold or not strip
          output.send
            out: packet
        groups.pop()
        return
    output.done()
