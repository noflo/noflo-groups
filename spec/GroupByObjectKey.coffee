describe 'GroupByObjectKey component', ->
  c = null
  ins = null
  key = null
  out = null
  error = null
  before (done) ->
    @timeout 4000
    loader = new noflo.ComponentLoader baseDir
    loader.load 'groups/GroupByObjectKey', (err, instance) ->
      return done err if err
      c = instance
      ins = noflo.internalSocket.createSocket()
      c.inPorts.in.attach ins
      key = noflo.internalSocket.createSocket()
      c.inPorts.key.attach key
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
  describe 'receiving an object that contains the desired key', ->
    it 'should send the packet with the group', (done) ->
      expected = [
        '< foo'
        {
          hello: 'foo'
          bar: 'baz'
        }
        '>'
      ]
      received = []
      out.on 'begingroup', (group) ->
        received.push "< #{group}"
      out.on 'data', (data) ->
        received.push data
        return unless received.length is expected.length
        chai.expect(received).to.eql expected
        done()
      out.on 'endgroup', ->
        received.push '>'
        return unless received.length is expected.length
        chai.expect(received).to.eql expected
        done()
      key.send 'hello'
      ins.send
        hello: 'foo'
        bar: 'baz'
      ins.disconnect()
  describe 'receiving an object that contains the desired key as non-string', ->
    it 'should send the packet with "undefined" group', (done) ->
      expected = [
        '< undefined'
        {
          hello: 42
          bar: 'baz'
        }
        '>'
      ]
      received = []
      out.on 'begingroup', (group) ->
        received.push "< #{group}"
      out.on 'data', (data) ->
        received.push data
        return unless received.length is expected.length
        chai.expect(received).to.eql expected
        done()
      out.on 'endgroup', ->
        received.push '>'
        return unless received.length is expected.length
        chai.expect(received).to.eql expected
        done()
      key.send 'hello'
      ins.send
        hello: 42
        bar: 'baz'
      ins.disconnect()
  describe 'receiving an object that doesn\'t contain the desired key', ->
    it 'should send the packet with "undefined" group', (done) ->
      expected = [
        '< undefined'
        {
          bar: 'baz'
        }
        '>'
      ]
      received = []
      out.on 'begingroup', (group) ->
        received.push "< #{group}"
      out.on 'data', (data) ->
        received.push data
        return unless received.length is expected.length
        chai.expect(received).to.eql expected
        done()
      out.on 'endgroup', ->
        received.push '>'
        return unless received.length is expected.length
        chai.expect(received).to.eql expected
        done()
      key.send 'hello'
      ins.send
        bar: 'baz'
      ins.disconnect()
  describe 'receiving something else than an object', ->
    it 'should send an error', (done) ->
      error.on 'data', (data) ->
        chai.expect(data).to.be.an 'error'
        done()
      out.on 'data', (data) ->
        done new Error 'Unexpected data received'
      key.send 'hello'
      ins.send 42
      ins.disconnect()
