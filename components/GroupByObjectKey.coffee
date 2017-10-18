noflo = require 'noflo'

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Group IPs by a key in their payload'
  c.inPorts.add 'in',
    datatype: 'object'
  c.inPorts.add 'key',
    datatype: 'string'
    control: true
  c.outPorts.add 'out',
    datatype: 'object'
  c.outPorts.add 'error',
    datatype: 'object'
  c.forwardBrackets = {}
  c.process (input, output) ->
    return unless input.hasData 'in', 'key'
    [data, key] = input.getData 'in', 'key'
    unless typeof data is 'object'
      output.done new Error 'Data is not an object'
      return
    group = data[key]
    unless typeof data[key] is 'string'
      group = 'undefined'
    if typeof data[key] is 'boolean'
      group = key if data[key]
    output.send
      out: new noflo.IP 'openBracket', group
    output.send
      out: data
    output.send
      out: new noflo.IP 'closeBracket', group
    output.done()
