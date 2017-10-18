noflo = require 'noflo'

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Collect packets to an object identified by keys organized
  by connection'
  c.inPorts.add 'keys',
    datatype: 'string'
    description: 'Comma-separated property names to be used for data based on connection index'
  c.inPorts.add 'allpackets',
    datatype: 'string'
    description: 'Comma-separated property names to collect all packets for in an array'
  c.inPorts.add 'collect',
    datatype: 'all'
    addressable: true
    description: 'Data IPs to collect'
  c.inPorts.add 'release',
    datatype: 'bang'
    description: 'Release all collected packets as an object'
  c.inPorts.add 'clear',
    datatype: 'bang'
    description: 'Clear all collected data'
  c.outPorts.add 'out',
    datatype: 'object'
  c.context = {}
  c.forwardBrackets = {}
  prepareContext = (scope) ->
    unless c.context[scope]
      c.context[scope] =
        data: {}
        groups: {}
        keys: []
        allpackets: []
    return c.context[scope]
  c.tearDown = (callback) ->
    c.context = {}
    do callback
  c.process (input, output) ->
    context = prepareContext input.scope
    if input.hasData 'keys'
      keys = input.getData('keys').split ','
      if keys.length > 1
        # Providing an array clears previous keys
        context.keys = []
      context.keys = context.keys.concat keys
      output.done()
      return
    if input.hasData 'allpackets'
      keys = input.getData('allpackets').split ','
      if keys.length > 1
        # Providing an array clears previous keys
        context.allpackets = []
      context.allpackets = context.allpackets.concat keys
      output.done()
      return
    if input.hasData 'release'
      input.getData 'release'
      output.send
        out: context.data
      context.data = {}
      output.done()
      return
    if input.hasData 'clear'
      input.getData 'clear'
      delete c.context[input.scope]
      output.done()
      return
    indexesWithIps = input.attached('collect').filter (idx) ->
      input.has ['collect', idx]
    return unless indexesWithIps.length
    # Ensure we have received keys before storing data
    return if input.attached('keys').length and not context.keys.length
    # Ensure we have received allpackets before storing data
    return if input.attached('allpackets').length and not context.allpackets.length
    indexesWithIps.forEach (idx) ->
      packet = input.get ['collect', idx]
      # Check that we have a named key for this connection
      return unless context.keys[idx]

      context.groups[idx] = [] unless context.groups[idx]
      if packet.type is 'openBracket'
        context.groups[idx].push packet.data
        return
      if packet.type is 'data'
        key = context.keys[idx]
        if context.groups[idx].length
          # First level key is the group name, if any
          groupId = context.groups[idx][0]
          context.data[groupId] = {} unless context.data[groupId]
          data = context.data[groupId]
        else
          # Ungrouped data goes to top-level
          data = context.data

        if context.allpackets[idx]
          # We're collecting all packets for this connection
          data[key] = [] unless data[key]
          data[key].push packet.data
          return
        data[key] = packet.data
        return
      if packet.type is 'closeBracket'
        context.groups[idx].pop()
        return
    output.done()
