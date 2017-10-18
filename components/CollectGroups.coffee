noflo = require 'noflo'

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Collect a stream of packets into object keyed by its groups'
  c.inPorts.add 'in',
    datatype: 'all'
    description: 'IPs to collect'
  c.outPorts.add 'out',
    datatype: 'object'
    description: 'An object containing input IPs sorted by their group
     names'
  c.outPorts.add 'error',
    datatype: 'object'
  c.forwardBrackets = {}
  c.process (input, output) ->
    return unless input.hasStream 'in'
    stream = input.getStream 'in'
    if stream[0].type is 'openBracket' and stream[0].data is null
      # Remove the surrounding brackets
      before = stream.shift()
      after = stream.pop()

    # Working variable for incoming IPs
    data = {}
    # Breadcrumb of incoming groups
    groups = []
    # Breadcrumb of each level of IPs as partitioned by groups
    parents = []

    for packet in stream
      if packet.type is 'openBracket'
        # We use the attribute name `$data` to indicate data IPs in the outgoing
        # structure, so no `$data` please
        if packet.data is '$data'
          output.done new Error 'groups cannot be named \'$data\''
          return
        # Save whatever in the working memory right now into its own level
        parents.push data
        # Save the current group
        groups.push packet.data
        # Clear working memory for new level
        data = {}
        continue
      if packet.type is 'data'
        # Initialize our data IPs storage as an array if it doesn't exist
        data.$data ?= []
        # Save the IP
        data.$data.push packet.data
        continue
      if packet.type is 'closeBracket'
        # Temporarily save working memory. Yes, you read me right! This is the
        # working memory of working memory. :)
        oldData = data
        # Take out the previous level
        data = parents.pop()
        # Take the working memory (`data`) and put it into the previous level
        # (`@data`) by a group name (`@groups.pop()`)
        child = groups.pop()
        # If `child` (i.e. the group) doesn't exist, simply put working memory
        # in as-is
        unless child of data
          data[child] = oldData unless child of data
          continue
        # *OR*, if it's already an array, append to it
        if Array.isArray data[child]
          data[child].push oldData
          continue
        # *OR*, if something already exists in place but isn't appendable, make
        # it so by having whatever in it as the first element of the array
        data[child] = [ data[child], oldData ]
        # NOTE: it may sound odd that collating into working memory (`@data`)
        # works. It does because this is ending a group (i.e. level). If what
        # follows is a disconnect, then it flushes the working memory, which is
        # the entire data structure anyway. If what follows is a new group, the
        # working memory is pushed into the level breadcrumbs (`@parents`)
        # anyway. If it's a data IP, it's saved into the `$data` attribute, not
        # affecting the data structure.

    # Flush everything down the drain
    output.sendDone
      out: data
