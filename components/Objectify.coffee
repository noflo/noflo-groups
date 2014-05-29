noflo = require("noflo")
_ = require("underscore")

class Objectify extends noflo.Component

  description: "specify a regexp string, use the first match as the key
  of an object containing the data"

  constructor: ->
    @regexp = null
    @match = null

    @inPorts = new noflo.InPorts
      in:
        datatype: 'all'
      regexp:
        datatype: 'string'
    @outPorts = new noflo.OutPorts
      out:
        datatype: 'all'

    @inPorts.regexp.on "data", (regexp) =>
      @regexp = new RegExp(regexp)

    @inPorts.in.on "begingroup", (group) =>
      if @regexp? and group.match(@regexp)?
        @match = _.first group.match @regexp

      @outPorts.out.beginGroup(group)

    @inPorts.in.on "data", (data) =>
      # If there is a match, make an object out of it
      if @match?
        d = data
        data = {}
        data[@match] = d

      @outPorts.out.send(data)

    @inPorts.in.on "endgroup", (group) =>
      @outPorts.out.endGroup()

    @inPorts.in.on "disconnect", =>
      @outPorts.out.disconnect()

exports.getComponent = -> new Objectify
