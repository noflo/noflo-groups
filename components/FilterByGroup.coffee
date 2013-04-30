noflo = require("noflo")
_s = require("underscore.string")

class FilterByGroup extends noflo.Component

  description: _s.clean "Given a RegExp string, filter out groups that do not
  match and their children data packets/groups. Forward only the content of the
  matching group."

  constructor: ->
    @regexp = null
    @matchedLevel = null

    @inPorts =
      in: new noflo.Port
      regexp: new noflo.Port
    @outPorts =
      out: new noflo.Port
      group: new noflo.Port

    @inPorts.regexp.on "data", (regexp) =>
      @regexp = new RegExp(regexp)

    @inPorts.in.on "connect", =>
      @level = 0

    @inPorts.in.on "begingroup", (group) =>
      if @matchedLevel?
        @outPorts.out.beginGroup(group)

      @level++

      if not @matchedLevel? and @regexp? and group.match(@regexp)?
        @matchedLevel = @level
        @outPorts.group.send(group)
        @outPorts.group.disconnect()

    @inPorts.in.on "data", (data) =>
      if @matchedLevel?
        @outPorts.out.send(data)

    @inPorts.in.on "endgroup", (group) =>
      if @matchedLevel is @level
        @matchedLevel = null

      if @matchedLevel?
        @outPorts.out.endGroup()

      @level--

    @inPorts.in.on "disconnect", =>
      @outPorts.out.disconnect()

exports.getComponent = -> new FilterByGroup
