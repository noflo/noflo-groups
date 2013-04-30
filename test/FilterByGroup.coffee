test = require "noflo-test"

test.component("groups/FilterByGroup").
  discuss("provide a group").
    send.data("regexp", "a.+").
  discuss("send some grouped IPs").
    send.connect("in").
      send.beginGroup("in", "abc").
        send.data("in", 1).
      send.endGroup("in").
      send.beginGroup("in", "pqr").
        send.data("in", 2).
      send.endGroup("in").
      send.beginGroup("in", "xyz").
        send.data("in", 3).
      send.endGroup("in").
    send.disconnect("in").
  discuss("only get back the content with a matching top-level group with the match via another port").
    receive.data("group", "abc").
    receive.data("out", 1).

  next().
  discuss("provide a group").
    send.data("regexp", "a.+").
  discuss("send some multi-layer grouped IPs").
    send.connect("in").
      send.beginGroup("in", "abc").
        send.data("in", 1).
        send.beginGroup("in", "xyz").
          send.data("in", 3).
        send.endGroup("in").
      send.endGroup("in").
      send.beginGroup("in", "pqr").
        send.data("in", 2).
      send.endGroup("in").
    send.disconnect("in").
  discuss("gets sub-groups and content too").
    receive.data("group", "abc").
    receive.data("out", 1).
    receive.beginGroup("out", "xyz").
      receive.data("out", 3).
    receive.endGroup("out").

export module
