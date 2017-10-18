noflo = require("noflo")

exports.getComponent = ->
  c = new noflo.Component
  c.description = "Given a RegExp string, filter out groups that do not
  match and their children data packets/groups. Forward only the content
  of the matching group."
  c.inPorts.add 'in',
    datatype: 'all'
    description: 'IPs to filter groups from'
    addressable: true
  c.inPorts.add 'regexp',
    datatype: 'string'
    description: 'Regexp use as a filter for IPs'
    control: true
  c.outPorts.add 'out',
    datatype: 'all'
  c.outPorts.add 'group',
    datatype: 'string'
  c.outPorts.add 'empty',
    datatype: 'bang'
  c.scopes = {}
  c.tearDown = (callback) ->
    c.scopes = {}
  ensureScope = (scope, idx) ->
    c.scopes[scope] = {} unless c.scopes[scope]
    return c.scopes[scope][idx] if c.scopes[scope][idx]
    c.scopes[scope][idx] =
      level: 0
      hasContent: false
      matchedLevel: null
    return c.scopes[scope][idx]
  c.forwardBrackets = {}
  c.process (input, output) ->
    indexesWithIps = input.attached('in').filter (idx) ->
      input.has ['in', idx]
    return unless indexesWithIps.length
    return unless input.hasData 'regexp'
    regexp = new RegExp input.getData 'regexp'
    indexesWithIps.forEach (idx) ->
      scope = ensureScope input.scope, idx
      packet = input.get ['in', idx]
      if packet.type is 'openBracket'
        if scope.matchedLevel?
          output.send
            out: new noflo.IP 'openBracket', packet.data
        scope.level++
        if not scope.matchedLevel? and packet.data.match(regexp)?
          scope.matchedLevel = scope.level
          output.send
            group: packet.data
        return
      if packet.type is 'data'
        return unless scope.matchedLevel?
        scope.hasContent = true
        output.send
          out: packet
        return
      if packet.type is 'closeBracket'
        if scope.matchedLevel is scope.level
          scope.matchedLevel = null
        if scope.matchedLevel?
          output.send
            out: new noflo.IP 'closeBracket', packet.data
        scope.level--
        return if scope.level
        unless scope.hasContent
          output.send
            empty: null
    output.done()
