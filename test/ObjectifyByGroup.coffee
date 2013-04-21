test = require "noflo-test"

test.component("groups/ObjectifyByGroup").
  discuss("provide a regexp string").
    send.data("regexp", "^(a)").
  discuss("send in some matching groups").
    send.beginGroup("in", "abc").
    send.data("in", "whatever").
    send.endGroup("in").
  discuss("becomes an object, without the groups").
    receive.data("out", { a: "whatever" }).

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
