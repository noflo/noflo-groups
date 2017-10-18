noflo = require("noflo")

exports.getComponent = ->
  c = new noflo.Component
  c.description = "specify a regexp string, use the first match as the key
  of an object containing the data"
  c.inPorts.add 'in',
    datatype: 'all'
    addressable: true
  c.inPorts.add 'regexp',
    datatype: 'string'
    control: true
  c.outPorts.add 'out',
    datatype: 'all'
  c.forwardBrackets = {}
  c.matches = {}
  c.tearDown = (callback) ->
    c.matches = {}
  ensureMatches = (scope, idx) ->
    c.matches[scope] = {} unless c.matches[scope]
    c.matches[scope][idx] = null unless c.matches[scope][idx]
    return c.matches[scope][idx]
  c.forwardBrackets = {}
  c.process (input, output) ->
    return unless input.hasData 'regexp'
    indexesWithIps = input.attached('in').filter (idx) ->
      input.has ['in', idx]
    return unless indexesWithIps.length
    regexp = new RegExp input.getData 'regexp'
    indexesWithIps.forEach (idx) ->
      matches = ensureMatches input.scope, idx
      packet = input.get ['in', idx]
      if packet.type is 'openBracket'
        if typeof packet.data is 'string' and packet.data.match regexp
          c.matches[input.scope][idx] = packet.data.match(regexp)[0]
        output.send
          out: packet
        return
      if packet.type is 'data'
        # If there is a match, make an object out of it
        if matches?
          d = packet.data
          data = {}
          data[matches] = d
          output.send
            out: data
          return
        output.send
          out: packet
        return
      if packet.type is 'closeBracket'
        c.matches[input.scope][idx] = null
        output.send
          out: packet
        return
    output.done()
