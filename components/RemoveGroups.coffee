noflo = require "noflo"

exports.getComponent = ->
  c = new noflo.Component
  c.description = "Remove groups matching a string or a regex string, or all if no regexp given"
  c.inPorts.add 'in',
    datatype: 'all'
    description: 'IPs to forward'
  c.inPorts.add 'regexp',
    datatype: 'string'
    description: 'Regexp used to remove groups'
    control: true
  c.outPorts.add 'out',
    datatype: 'all'
  c.forwardBrackets = {}
  c.process (input, output) ->
    return unless input.has 'in'
    return if input.attached('regexp').length and not input.hasData 'regexp'
    regexp = null
    if input.hasData 'regexp'
      regexp = new RegExp input.getData 'regexp'
    packet = input.get 'in'
    if packet.type in ['openBracket', 'closeBracket']
      unless regexp
        # No regexp given, remove all brackets
        output.done()
        return
      if typeof packet.data is 'string' and packet.data.match(regexp)
        # Matches regexp, remove
        output.done()
        return
      # Doesn't match regexp, send
      output.sendDone
        out: packet
      return
    if packet.type is 'data'
      output.sendDone
        out: packet
      return
