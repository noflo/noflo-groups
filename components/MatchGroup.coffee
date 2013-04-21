noflo = require("noflo")

class MatchGroup extends noflo.Component

  description: "send data of matched groups to right, otherwise left"

  constructor: ->
    @groups = []
    @regexps = []
    @matchGroups = []
    @match = false

    @inPorts =
      in: new noflo.Port
      regexp: new noflo.ArrayPort
      group: new noflo.ArrayPort
    @outPorts =
      left: new noflo.Port
      right: new noflo.Port

    @inPorts.in.on "begingroup", (group) =>
      @examineGroup(group, true)
      @groups.push(group)

    @inPorts.in.on "data", (data) =>
      # Send to right on matched group(s)
      port = @outPorts[(if @match then "right" else "left")]

      for group in @groups
        port.beginGroup(group)

      port.send(data)

      for group in @groups
        port.endGroup()

    @inPorts.in.on "endgroup", (group) =>
      @examineGroup(group, false)
      @groups.pop()

    @inPorts.in.on "disconnect", =>
      # Disconnect both routes
      @outPorts.left.disconnect()
      @outPorts.right.disconnect()
      @groups = []

    @inPorts.group.on "data", (data) =>
      @matchGroups.push(data)

    @inPorts.regexp.on "data", (data) =>
      @regexps.push(data)

  # Examine the group for matches
  #
  # @param {String} group The group
  # @param {Boolean} isBeginning Whether it's a 'begingroup' or an 'endgroup'
  examineGroup: (group, isBeginning) ->
    # Full matches
    for matchGroup in @matchGroups
      if matchGroup is group
        # If there is a match and it's a 'begingroup', always set match to true; otherwise, always set match to false
        @match = isBeginning

    # RegExp matches
    for regexp in @regexps
      if group.match(regexp)?
        @match = isBeginning

exports.getComponent = -> new MatchGroup
