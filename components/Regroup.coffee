noflo = require("noflo")

exports.getComponent = ->
  c = new noflo.Component
  c.description = "Forward all the data IPs, strip all groups, and replace
  them with groups from another connection"
  c.inPorts.add 'in',
    datatype: 'all'
  c.inPorts.add 'group',
    datatype: 'string'
  c.outPorts.add 'out',
    datatype: 'all'
  c.groups = {}
  c.tearDown = (callback) ->
    c.groups = {}
    do callback
  c.forwardBrackets = {}
  c.process (input, output) ->
    if input.hasData 'group'
      c.groups[input.scope] = [] unless c.groups[input.scope]
      c.groups[input.scope].push input.getData 'group'
      output.done()
      return
    return unless input.hasData 'in'
    groups = []
    if c.groups[input.scope]?.length
      groups = c.groups[input.scope].slice 0
    data = input.getData 'in'
    for group in groups
      output.send
        out: new noflo.IP 'openBracket', group
    output.send
      out: data
    groups.reverse()
    for group in groups
      output.send
        out: new noflo.IP 'closeBracket', group
    output.done()
