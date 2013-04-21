test = require "noflo-test"

test.component("groups/Regroup").
  discuss("pass in a grouped connection").
    send.connect("in").
      send.beginGroup("in", "group").
      send.data("in", "data").
      send.endGroup("in").
    send.disconnect("in").
  discuss("all groups are stripped").
    receive.connect("out").
      receive.data("out", "data").
    receive.disconnect("out").

  next().
  discuss("pass in some replacement groups").
    send.connect("group").
      send.data("group", "group1").
      send.data("group", "group2").
      send.data("group", "group3").
    send.disconnect("group").
  discuss("pass in a grouped connection").
    send.connect("in").
      send.beginGroup("in", "group").
        send.data("in", "data").
      send.endGroup("in").
    send.disconnect("in").
  discuss("replacement groups are put in").
    receive.connect("out").
      receive.beginGroup("out", "group1").
      receive.beginGroup("out", "group2").
      receive.beginGroup("out", "group3").
      receive.data("out", "data").
      receive.endGroup("out").
      receive.endGroup("out").
      receive.endGroup("out").
    receive.disconnect("out").

export module
