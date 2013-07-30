noflo = require 'noflo'

if typeof process is 'object' and process.title is 'node'
  chai = require 'chai' unless chai
  CollectGroups = require '../components/CollectGroups.coffee'
else
  CollectGroups = require 'noflo-core/components/CollectGroups.js'

describe 'CollectGroups component', ->
  c = null
  ins = null
  out = null

  beforeEach ->
    c = CollectGroups.getComponent()
    c.inPorts.in.attach noflo.internalSocket.createSocket()
    c.outPorts.out.attach noflo.internalSocket.createSocket()
    ins = c.inPorts.in
    out = c.outPorts.out

  describe 'when instantiated', ->
    it 'should have input ports', ->
      chai.expect(c.inPorts.in).to.be.an 'object'

    it 'should have an output port', ->
      chai.expect(c.outPorts.out).to.be.an 'object'

  it "test no groups", (done) ->
    output = []
    out.on "data", (data) ->
      output.push data
    out.once "disconnect", ->
      chai.expect(output).to.deep.equal [{ $data: ["a","b","c"] }]
      done()
    ins.send "a"
    ins.send "b"
    ins.send "c"
    ins.disconnect()

  it "test one group", (done) ->
    output = []
    expect =
      g1:
        $data: ["a","b"]
      $data: ["c"]
    out.on "data", (data) ->
      output.push data
    out.once "disconnect", ->
      chai.expect(output).to.deep.equal [expect]
      done()
    ins.beginGroup "g1"
    ins.send "a"
    ins.send "b"
    ins.endGroup()
    ins.send "c"
    ins.disconnect()

  it "test group named $data", (done) ->
    chai.expect(-> ins.beginGroup "$data").to.throw "groups cannot be named '$data'"
    done()

  it "test group named $data with attached error port", (done) ->
    err = noflo.internalSocket.createSocket()
    c.outPorts.error.attach err

    err.on 'data', (data) ->
      chai.expect(data).to.be.ok
      done()
    ins.beginGroup '$data'

  it "test two groups", (done) ->
    output = []
    expect =
      g1:
        $data: ["a","b"]
      g2:
        $data: ["c","d"]
    out.on "data", (data) ->
      output.push data
    out.once "disconnect", ->
      chai.expect(output).to.deep.equal [expect]
      done()
    ins.beginGroup "g1"
    ins.send "a"
    ins.send "b"
    ins.endGroup()
    ins.beginGroup "g2"
    ins.send "c"
    ins.send "d"
    ins.endGroup()
    ins.disconnect()

  it "test two groups with same name", (done) ->
    output = []
    expect =
      g1: [ { $data: ["a","b"] }, { $data: ["c","d"] } ]
    out.on "data", (data) ->
      output.push data
    out.once "disconnect", ->
      chai.expect(output).to.deep.equal [expect]
      done()
    ins.beginGroup "g1"
    ins.send "a"
    ins.send "b"
    ins.endGroup()
    ins.beginGroup "g1"
    ins.send "c"
    ins.send "d"
    ins.endGroup()
    ins.disconnect()

  it "test nested groups", (done) ->
    output = []
    expect =
      g1:
        $data: ["a","b"]
        g2:
          $data: ["c","d"]
    out.on "data", (data) ->
      output.push data
    out.once "disconnect", ->
      chai.expect(output).to.deep.equal [expect]
      done()
    ins.beginGroup "g1"
    ins.send "a"
    ins.beginGroup "g2"
    ins.send "c"
    ins.send "d"
    ins.endGroup()
    ins.send "b"
    ins.endGroup()
    ins.disconnect()

  it "test object data", (done) ->
    output = []
    expect =
      g1:
        $data: [ {a:1,b:2}, {b:3,c:4} ]
    out.on "data", (data) ->
      output.push data
    out.once "disconnect", ->
      chai.expect(output).to.deep.equal [expect]
      done()
    ins.beginGroup "g1"
    ins.send {a:1,b:2}
    ins.send {b:3,c:4}
    ins.endGroup()
    ins.disconnect()

  it "test array data", (done) ->
    output = []
    expect =
      g1:
        $data: [ ["a","b"], ["c","d"] ]
    out.on "data", (data) ->
      output.push data
    out.once "disconnect", ->
      chai.expect(output).to.deep.equal [expect]
      done()
    ins.beginGroup "g1"
    ins.send ["a","b"]
    ins.send ["c","d"]
    ins.endGroup()
    ins.disconnect()
