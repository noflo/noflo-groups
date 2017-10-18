noflo = require 'noflo'

getIdentifier = (groups) ->
  if groups.length
    return groups.join ':'
  return 'ungrouped'

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Send packet held in "data" when receiving
  matching set of groups in "in"'
  c.icon = 'share-square'
  c.inPorts.add 'in',
    datatype: 'bang'
    description: 'Signal to release IPs associated with the emitted group'
  c.inPorts.add 'data',
    datatype: 'all'
    description: 'IP to store by group'
    addressable: true
  c.outPorts.add 'out',
    datatype: 'all'
    description: 'IP associated with a group received on the in port'
  c.stored = {}
  c.released = {}
  c.groups = []
  c.tearDown = (callback) ->
    c.stored = {}
    c.released = {}
    c.groups = []
    do callback
  c.forwardBrackets = {}
  c.process (input, output) ->

    release = (groups) ->
      identifier = getIdentifier groups
      c.released[input.scope] = {} unless c.released[input.scope]
      c.released[input.scope][identifier] = true
      return unless c.stored[input.scope]
      return unless c.stored[input.scope][identifier]
      for group in groups
        output.send
          out: new noflo.IP 'openBracket', group
      output.send
        out: c.stored[input.scope][identifier]
      closes = groups.slice 0
      closes.reverse()
      for group in closes
        output.send
          out: new noflo.IP 'closeBracket', group
      # Mark as non-released after sending
      c.released[input.scope][identifier] = false
      return
    if input.hasStream 'in'
      # Time to release some data
      stream = input.getStream 'in'
      brackets = []
      for packet in stream
        if packet.type is 'openBracket'
          brackets.push packet.data
          continue
        if packet.type is 'data'
          release brackets
          continue
        if packet.type is 'closeBracket'
          brackets.pop()
          continue
      output.done()
      return

    # Store data to be released
    indexesWithIps = input.attached('data').filter (idx) ->
      input.has ['data', idx]
    return unless indexesWithIps.length
    indexesWithIps.forEach (idx) ->
      c.groups[input.scope] = {} unless c.groups[input.scope]
      c.groups[input.scope][idx] = [] unless c.groups[input.scope][idx]
      packet = input.get ['data', idx]
      if packet.type is 'openBracket'
        c.groups[input.scope][idx].push packet.data
        return
      if packet.type is 'data'
        identifier = getIdentifier c.groups[input.scope][idx]
        c.stored[input.scope] = {} unless c.stored[input.scope]
        c.stored[input.scope][identifier] = packet
        if c.released[input.scope]?[identifier]
          # This identifier was already released. Send right away
          release c.groups[input.scope][idx]
        return
      if packet.type is 'closeBracket'
        c.groups[input.scope][idx].pop()
        return
    output.done()
