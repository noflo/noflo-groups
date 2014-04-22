test = require "noflo-test"

test.component("groups/LastGroup").
  discuss("pass no group").
    send.connect("in").
      send.data("in", "data").
    send.disconnect("in").
  discuss("no group is sent").
    receive.connect("out").
      receive.data("out", "data").
    receive.disconnect("out").

  next().
  discuss("pass one group & data").
    send.connect("in").
      send.beginGroup("in", "group").
        send.data("in", "data").
      send.endGroup("in").
    send.disconnect("in").
  discuss("one group is sent").
    receive.connect("out").
      receive.beginGroup("out", "group").
        receive.data("out", "data").
      receive.endGroup("out").
    receive.disconnect("out").

  next().
  discuss("pass 2 groups & data").
    send.connect("in").
      send.beginGroup("in", "group1").
        send.beginGroup("in", "group2").
          send.data("in", "data").
        send.endGroup("in").
      send.endGroup("in").
    send.disconnect("in").
  discuss("one group is sent").
    receive.connect("out").
      receive.beginGroup("out", "group2").
        receive.data("out", "data").
      receive.endGroup("out").
    receive.disconnect("out").

export module
