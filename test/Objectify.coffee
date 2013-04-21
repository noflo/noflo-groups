test = require "noflo-test"

test.component("groups/Objectify").
  discuss("provide a regexp string").
    send.data("regexp", "^(a)").
  discuss("send in some matching groups").
    send.beginGroup("in", "abc").
    send.data("in", "whatever").
    send.endGroup("in").
  discuss("becomes an object, retaining the groups").
    receive.beginGroup("out", "abc").
    receive.data("out", { a: "whatever" }).
    receive.endGroup("out").

  next().
  discuss("provide a regexp string").
    send.data("regexp", "^(a)").
  discuss("send in some *non*-matching groups").
    send.beginGroup("in", "xyz").
    send.data("in", "whatever").
    send.endGroup("in").
  discuss("the group passes through").
    receive.beginGroup("out", "xyz").
    receive.data("out", "whatever").
    receive.endGroup("out").

export module
