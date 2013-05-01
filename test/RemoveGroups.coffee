test = require "noflo-test"

test.component("groups/RemoveGroups").
  discuss("provide a regexp").
    send.data("regexp", "abc").
  discuss("provide some grouped packets").
    send.connect("in").
      send.beginGroup("in", "abcd").
        send.data("in", "matched").
      send.endGroup("in").
      send.beginGroup("in", "wxyz").
        send.data("in", "umatched").
      send.endGroup("in").
    send.disconnect("in").
  discuss("remove groups matching the regexp").
    receive.connect("out").
      receive.data("out", "matched").
      receive.beginGroup("out", "wxyz").
        receive.data("out", "umatched").
      receive.endGroup("out").
    receive.disconnect("out").

  next().
  discuss("provide some grouped packets").
    send.connect("in").
      send.beginGroup("in", "abcd").
        send.data("in", "matched").
      send.endGroup("in").
      send.beginGroup("in", "wxyz").
        send.data("in", "umatched").
      send.endGroup("in").
    send.disconnect("in").
  discuss("remove all groups if no regexp is provided").
    receive.connect("out").
      receive.data("out", "matched").
      receive.data("out", "umatched").
    receive.disconnect("out").

export module
