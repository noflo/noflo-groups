test = require "noflo-test"

test.component("groups/GroupZip").
  discuss("provide some groups").
    send.data("group", "groupA").
    send.data("group", "groupB").
    send.data("group", "groupC").
  discuss("provide some packets").
    send.data("in", "packetA").
    send.data("in", "packetB").
    send.data("in", "packetC").
    send.endGroup("in").
  discuss("each group groups the corresponding packet by position").
    receive.beginGroup("out", "groupA").
    receive.data("out", "packetA").
    receive.endGroup("out").
    receive.beginGroup("out", "groupB").
    receive.data("out", "packetB").
    receive.endGroup("out").
    receive.beginGroup("out", "groupC").
    receive.data("out", "packetC").
    receive.endGroup("out").

export module
