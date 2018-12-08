describe 'CollectGroups component', ->
  c = null
  ins = null
  out = null
  error = null
  before (done) ->
    @timeout 4000
    loader = new noflo.ComponentLoader baseDir
    loader.load 'groups/CollectGroups', (err, instance) ->
      return done err if err
      c = instance
      ins = noflo.internalSocket.createSocket()
      c.inPorts.in.attach ins
      done()
  beforeEach ->
    out = noflo.internalSocket.createSocket()
    c.outPorts.out.attach out
    error = noflo.internalSocket.createSocket()
    c.outPorts.error.attach error
  afterEach ->
    c.outPorts.out.detach out
    out = null
    c.outPorts.error.detach error
    error = null

  it "test no brackets inside stream", (done) ->
    output = []
    error.on 'data', done
    out.on "data", (data) ->
      output.push data
    out.once "disconnect", ->
      chai.expect(output).to.deep.equal [{ $data: ["a","b","c"] }]
      done()
    ins.beginGroup()
    ins.send "a"
    ins.send "b"
    ins.send "c"
    ins.endGroup()

  it "test one group", (done) ->
    output = []
    expect =
      g1:
        $data: ["a","b"]
      $data: ["c"]
    error.on 'data', done
    out.on "data", (data) ->
      output.push data
    out.once "disconnect", ->
      chai.expect(output).to.deep.equal [expect]
      done()
    ins.beginGroup()
    ins.beginGroup "g1"
    ins.send "a"
    ins.send "b"
    ins.endGroup()
    ins.send "c"
    ins.endGroup()

  it "test group named $data", (done) ->
    error.on 'data', (err) ->
      chai.expect(err).to.be.an 'error'
      chai.expect(err.message).to.equal "groups cannot be named '$data'"
    ins.beginGroup '$data'
    ins.send 1
    ins.endGroup()
    done()

  it "test two groups", (done) ->
    output = []
    expect =
      g1:
        $data: ["a","b"]
      g2:
        $data: ["c","d"]
    error.on 'data', done
    out.on "data", (data) ->
      output.push data
    out.once "disconnect", ->
      chai.expect(output).to.deep.equal [expect]
      done()
    ins.beginGroup()
    ins.beginGroup "g1"
    ins.send "a"
    ins.send "b"
    ins.endGroup()
    ins.beginGroup "g2"
    ins.send "c"
    ins.send "d"
    ins.endGroup()
    ins.endGroup()

  it "test two groups with same name", (done) ->
    output = []
    expect =
      g1: [ { $data: ["a","b"] }, { $data: ["c","d"] } ]
    error.on 'data', done
    out.on "data", (data) ->
      output.push data
    out.once "disconnect", ->
      chai.expect(output).to.deep.equal [expect]
      done()
    ins.beginGroup()
    ins.beginGroup "g1"
    ins.send "a"
    ins.send "b"
    ins.endGroup()
    ins.beginGroup "g1"
    ins.send "c"
    ins.send "d"
    ins.endGroup()
    ins.endGroup()

  it "test nested groups", (done) ->
    output = []
    expect =
      g1:
        $data: ["a","b"]
        g2:
          $data: ["c","d"]
    error.on 'data', done
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

  it "test object data", (done) ->
    output = []
    expect =
      g1:
        $data: [ {a:1,b:2}, {b:3,c:4} ]
    error.on 'data', done
    out.on "data", (data) ->
      output.push data
    out.once "disconnect", ->
      chai.expect(output).to.deep.equal [expect]
      done()
    ins.beginGroup "g1"
    ins.send {a:1,b:2}
    ins.send {b:3,c:4}
    ins.endGroup()

  it "test array data", (done) ->
    output = []
    expect =
      g1:
        $data: [ ["a","b"], ["c","d"] ]
    error.on 'data', done
    out.on "data", (data) ->
      output.push data
    out.once "disconnect", ->
      chai.expect(output).to.deep.equal [expect]
      done()
    ins.beginGroup "g1"
    ins.send ["a","b"]
    ins.send ["c","d"]
    ins.endGroup()
