test = require "noflo-test"

test.component("groups/GenerateGroup").
  discuss("pass in a non grouped connection").
    send.connect("in").
      send.data("in", "data").
    send.disconnect("in").
  discuss("one groups is sent").
    receive.connect("out").
      receive.beginGroup("out").
      receive.data("out", "data").
      receive.endGroup("out").
    receive.disconnect("out").

  next().
  discuss("pass in a grouped connection").
    send.beginGroup("in", "group").
      send.data("in", "data").
    send.endGroup("in").
    send.disconnect("in").
  discuss("two groups are sent").
    receive.connect("out").
      receive.beginGroup("out", "group").
        receive.beginGroup("out").
          receive.data("out", "data").
        receive.endGroup("out").
      receive.endGroup("out").
    receive.disconnect("out").

  next().
  discuss("pass in a multi grouped connection").
    send.beginGroup("in", "group1").
      send.data("in", "data1").
      send.beginGroup("in", "group2").
        send.data("in", "data2").
      send.endGroup("in").
    send.endGroup("in").
    send.disconnect("in").
  discuss("four groups are sent").
    receive.connect("out").
      receive.beginGroup("out", "group").
        receive.beginGroup("out").
          receive.data("out", "data1").
          receive.beginGroup("out", "group2").
            receive.beginGroup("out").
              receive.data("out", "data2").
            receive.endGroup("out").
          receive.endGroup("out").
        receive.endGroup("out").
      receive.endGroup("out").
    receive.disconnect("out").

export module
