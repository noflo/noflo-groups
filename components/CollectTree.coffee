noflo = require 'noflo'

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Collect a stream of packets into a simple tree structure'
  c.inPorts.add 'in',
    datatype: 'all'
  c.inPorts.add 'level',
    datatype: 'integer'
    default: 0
    description: 'Number of groups (from outermost) to skip collection of'
    control: true
  c.outPorts.add 'out',
    datatype: 'object'
  c.outPorts.add 'error',
    datatype: 'object'
  c.forwardBrackets = {}
  c.process (input, output) ->
    return unless input.hasStream 'in'
    return if input.attached('level').length and not input.hasData 'level'

    level = if input.hasData('level') then input.getData('level') else 0

    stream = input.getStream 'in'
    if stream[0].type is 'openBracket' and stream[0].data is null
      # Remove the surrounding brackets if they're unnamed
      before = stream.shift()
      after = stream.pop()

    data = {}
    currentLevel = 0
    collectGroups = []
    forwardGroups = []

    for packet in stream
      if packet.type is 'openBracket'
        if currentLevel < level
          forwardGroups.push packet.data
        else
          collectGroups.push packet.data
        currentLevel += 1
        continue
      if packet.type is 'data'
        continue unless collectGroups.length
        d = data
        for g, idx in collectGroups
          if idx < collectGroups.length - 1
            d[g] = {} unless d[g]
            d = d[g]
            continue
        unless d[g]
          d[g] = packet.data
          continue
        unless Array.isArray d[g]
          d[g] = [d[g]]
        d[g].push packet.data
        continue
      if packet.type is 'closeBracket'
        if currentLevel < level
          # will be sent & reset on disconnect
        else
          collectGroups.pop()
        currentLevel -= 1
        continue

    unless Object.keys(data).length
      output.done new Error 'No tree information was collected'
      return

    for group in forwardGroups
      output.send
        out: new noflo.IP 'openBracket', group
    output.send
      out: data
    forwardGroups.reverse()
    for group in forwardGroups
      output.send
        out: new noflo.IP 'closeBracket', group
    output.done()
    return
