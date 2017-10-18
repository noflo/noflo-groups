noflo = require 'noflo'
uuid = require 'uuid'

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Wrap IPs into a random UUID generated group'
  c.inPorts.add 'in',
    datatype: 'all'
    description: 'IPs to forward'
  c.outPorts.add 'out',
    datatype: 'all'
  c.process (input, output) ->
    return unless input.hasData 'in'
    data = input.getData 'in'
    identifier = uuid.v4()
    output.send
      out: new noflo.IP 'openBracket', identifier
    output.send
      out: data
    output.send
      out: new noflo.IP 'closeBracket', identifier
    output.done()
