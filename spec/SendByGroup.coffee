describe 'SendByGroup component', ->
  c = null
  regexp = null
  data = null
  ins = null
  out = null
  before (done) ->
    @timeout 4000
    loader = new noflo.ComponentLoader baseDir
    loader.load 'groups/SendByGroup', (err, instance) ->
      return done err if err
      c = instance
      ins = noflo.internalSocket.createSocket()
      data = noflo.internalSocket.createSocket()
      c.inPorts.in.attach ins
      c.inPorts.data.attach data
      done()
  beforeEach ->
    out = noflo.internalSocket.createSocket()
    c.outPorts.out.attach out
  afterEach (done) ->
    c.outPorts.out.detach out
    c.shutdown done

  describe 'receiving a single-level stream', ->
    it 'should not release the packets when receiving an unrelated bang', (done) ->
      expected = []
      received = []
      out.on 'begingroup', (group) ->
        received.push "< #{group}"
      out.on 'data', (d) ->
        received.push "DATA #{d}"
      out.on 'endgroup', ->
        received.push '>'
      data.beginGroup 'a'
      data.send 'hello'
      data.send 'world'
      data.endGroup()
      ins.beginGroup 'b'
      ins.send true
      ins.endGroup()
      setTimeout ->
        chai.expect(received).to.eql expected
        done()
      , 100

    it 'should release the last packet when receiving a bang', (done) ->
      expected = [
        '< a'
        'DATA world'
        '>'
      ]
      received = []
      out.on 'begingroup', (group) ->
        received.push "< #{group}"
      out.on 'data', (d) ->
        received.push "DATA #{d}"
      out.on 'endgroup', ->
        received.push '>'
      data.beginGroup 'a'
      data.send 'hello'
      data.send 'world'
      data.endGroup()
      ins.beginGroup 'a'
      ins.send true
      ins.endGroup()
      setTimeout ->
        chai.expect(received).to.eql expected
        done()
      , 100
  describe 'with a substream', ->
    it 'should release the last packet when receiving a bang', (done) ->
      expected = [
        '< a'
        '< b'
        'DATA world'
        '>'
        '>'
      ]
      received = []
      out.on 'begingroup', (group) ->
        received.push "< #{group}"
      out.on 'data', (d) ->
        received.push "DATA #{d}"
      out.on 'endgroup', ->
        received.push '>'
      data.beginGroup 'a'
      data.send 'hello'
      data.beginGroup 'b'
      data.send 'world'
      data.endGroup()
      data.endGroup()
      ins.beginGroup 'a'
      ins.beginGroup 'b'
      ins.send true
      ins.endGroup()
      ins.endGroup()
      setTimeout ->
        chai.expect(received).to.eql expected
        done()
      , 100
    it 'should release the last packet when receiving a bang of higher stream', (done) ->
      expected = [
        '< a'
        'DATA hello'
        '>'
      ]
      received = []
      out.on 'begingroup', (group) ->
        received.push "< #{group}"
      out.on 'data', (d) ->
        received.push "DATA #{d}"
      out.on 'endgroup', ->
        received.push '>'
      data.beginGroup 'a'
      data.send 'hello'
      data.beginGroup 'b'
      data.send 'world'
      data.endGroup()
      data.endGroup()
      ins.beginGroup 'a'
      ins.send true
      ins.endGroup()
      setTimeout ->
        chai.expect(received).to.eql expected
        done()
      , 100
    it 'should release the first packet immediately if bang was already received', (done) ->
      expected = [
        '< a'
        'DATA hello'
        '>'
      ]
      received = []
      out.on 'begingroup', (group) ->
        received.push "< #{group}"
      out.on 'data', (d) ->
        received.push "DATA #{d}"
      out.on 'endgroup', ->
        received.push '>'
      ins.beginGroup 'a'
      ins.send true
      ins.endGroup()
      data.beginGroup 'a'
      data.send 'hello'
      data.send 'world'
      data.endGroup()
      data.endGroup()
      setTimeout ->
        chai.expect(received).to.eql expected
        done()
      , 100
    it 'should release the ungrouped packet when receiving a ungrouped bang', (done) ->
      expected = [
        'DATA hello'
      ]
      received = []
      out.on 'begingroup', (group) ->
        received.push "< #{group}"
      out.on 'data', (d) ->
        received.push "DATA #{d}"
      out.on 'endgroup', ->
        received.push '>'
      data.beginGroup 'a'
      data.beginGroup 'b'
      data.send 'world'
      data.endGroup()
      data.endGroup()
      data.send 'hello'
      ins.send true
      setTimeout ->
        chai.expect(received).to.eql expected
        done()
      , 100
