noflo = require 'noflo'

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Replace groups based on static or regexp map'
  c.inPorts.add 'map',
    datatype: 'all'
    control: true
  c.inPorts.add 'regexp',
    datatype: 'all'
    control: true
  c.inPorts.add 'in',
    datatype: 'all'
  c.outPorts.add 'out',
    datatype: 'all'
  c.forwardBrackets = {}
  c.process (input, output) ->
    return unless input.has 'in'
    return if input.attached('map').length and not input.hasData 'map'
    return if input.attached('regexp').length and not input.hasData 'regexp'
    map = {}
    regexp = {}
    if input.hasData 'map'
      mapData = input.getData 'map'
      if typeof mapData is 'object'
        map = mapData
      else
        mapParts = mapData.split '='
        map[mapParts[0]] = mapParts[1]
    if input.hasData 'regexp'
      regexpData = input.getData 'regexp'
      if typeof regexpData is 'object'
        regexp = regexpData
      else
        regexpParts = regexpData.split '='
        regexp[regexpParts[0]] = regexpParts[1]
    packet = input.get 'in'
    if packet.type is 'data'
      output.sendDone
        out: packet
      return
    if packet.type in ['openBracket', 'closeBracket']
      unless typeof packet.data is 'string'
        output.sendDone
          out: packet
        return

      if map[packet.data]
        # Direct mapping
        output.sendDone
          out: new noflo.IP packet.type, map[packet.data]
        return

      group = packet.data
      for expression, replacement of regexp
        exp = new RegExp expression
        matched = exp.exec group
        continue unless matched
        group = group.replace exp, replacement
      output.sendDone
        out: new noflo.IP packet.type, group
      return
    output.done()
