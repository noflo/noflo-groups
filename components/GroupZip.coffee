noflo = require "noflo"

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Group packets by a group in order received'
  c.inPorts.add 'in',
    datatype: 'all'
  c.inPorts.add 'group',
    datatype: 'string'
  c.outPorts.add 'out',
    datatype: 'all'
  c.forwardBrackets = {}
  c.process (input, output) ->
    return unless input.hasData 'in', 'group'
    [data, group] = input.getData 'in', 'group'
    output.send
      out: new noflo.IP 'openBracket', group
    output.send
      out: data
    output.send
      out: new noflo.IP 'closeBracket', group
    output.done()
