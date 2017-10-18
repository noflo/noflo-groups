noflo = require "noflo"

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Surround data IPs brackets'
  c.inPorts.add 'in',
    datatype: 'all'
    description: 'IPs to forward'
  c.inPorts.add 'group',
    datatype: 'string'
    description: 'Groups to encapsulate incoming packets into'
    control: true
  c.outPorts.add 'out',
    datatype: 'all'
    description: 'Forwarded IPs with encapsulating groups'
  c.forwardBrackets = {}
  c.process (input, output) ->
    return unless input.hasData 'in', 'group'
    [data, group] = input.getData 'in', 'group'
    if Array.isArray group
      brackets = group.slice 0
    else
      brackets = group.split ':'
    for bracket in brackets
      output.send
        out: new noflo.IP 'openBracket', bracket
    output.send
      out: data
    brackets.reverse()
    for bracket in brackets
      output.send
        out: new noflo.IP 'closeBracket', bracket
    output.done()
