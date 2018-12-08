describe 'ReadGroups component', ->
  c = null
  ins = null
  group = null
  out = null
  strip = null
  threshold = null
  loader = null

  before ->
    loader = new noflo.ComponentLoader baseDir

  beforeEach (done) ->
    @timeout 4000
    loader.load 'groups/ReadGroups', (err, instance) ->
      return done err if err
      c = instance
      ins = noflo.internalSocket.createSocket()
      group = noflo.internalSocket.createSocket()
      out = noflo.internalSocket.createSocket()
      strip = noflo.internalSocket.createSocket()
      threshold = noflo.internalSocket.createSocket()
      c.inPorts.in.attach ins
      c.inPorts.strip.attach strip
      c.inPorts.threshold.attach threshold
      c.outPorts.group.attach group
      c.outPorts.out.attach out
      done()

  describe 'when instantiated', ->
    it 'should have input ports', ->
      chai.expect(c.inPorts.in).to.be.an 'object'

    it 'should have an output port', ->
      chai.expect(c.outPorts.group).to.be.an 'object'

  describe 'read groups', ->
    it 'test reading a group', (done) ->
      group.once 'data', (data) ->
        chai.expect(data).to.equal 'foo'
        done()
      strip.send false
      threshold.send Infinity
      ins.beginGroup 'foo'
      ins.send 'hello'
      ins.endGroup()

    it 'test reading a subgroup with threshold=2', (done) ->
      expected = [
        'GROUP foo'
        'OUT < foo'
        'GROUP bar'
        'OUT < bar'
        'OUT hello'
        'OUT >'
        'OUT >'
      ]
      received = []
      group.on 'data', (data) ->
        received.push "GROUP #{data}"
        return unless received.length is expected.length
        chai.expect(received).to.eql expected
        done()
      out.on 'begingroup', (group) ->
        received.push "OUT < #{group}"
      out.on 'data', (data) ->
        received.push "OUT #{data}"
        return unless received.length is expected.length
        chai.expect(received).to.eql expected
        done()
      out.on 'endgroup', (group) ->
        received.push "OUT >"
        return unless received.length is expected.length
        chai.expect(received).to.eql expected
        done()
      strip.send false
      threshold.send 2
      ins.beginGroup 'foo'
      ins.beginGroup 'bar'
      ins.send 'hello'
      ins.endGroup()
      ins.endGroup()
    it 'test reading a subgroup with threshold=1', (done) ->
      expected = [
        'GROUP foo'
        'OUT < foo'
        'OUT < bar'
        'OUT hello'
        'OUT >'
        'OUT >'
      ]
      received = []
      group.on 'data', (data) ->
        received.push "GROUP #{data}"
        return unless received.length is expected.length
        chai.expect(received).to.eql expected
        done()
      out.on 'begingroup', (group) ->
        received.push "OUT < #{group}"
      out.on 'data', (data) ->
        received.push "OUT #{data}"
        return unless received.length is expected.length
        chai.expect(received).to.eql expected
        done()
      out.on 'endgroup', (group) ->
        received.push "OUT >"
        return unless received.length is expected.length
        chai.expect(received).to.eql expected
        done()
      strip.send false
      threshold.send 1
      ins.beginGroup 'foo'
      ins.beginGroup 'bar'
      ins.send 'hello'
      ins.endGroup()
      ins.endGroup()
    it 'test reading a subgroup with threshold=2 and strip=true', (done) ->
      expected = [
        'GROUP foo'
        'GROUP bar'
        'OUT hello'
      ]
      received = []
      group.on 'data', (data) ->
        received.push "GROUP #{data}"
        return unless received.length is expected.length
        chai.expect(received).to.eql expected
        done()
      out.on 'begingroup', (group) ->
        received.push "OUT < #{group}"
      out.on 'data', (data) ->
        received.push "OUT #{data}"
        return unless received.length is expected.length
        chai.expect(received).to.eql expected
        done()
      out.on 'endgroup', (group) ->
        received.push "OUT >"
        return unless received.length is expected.length
        chai.expect(received).to.eql expected
        done()
      strip.send true
      threshold.send 2
      ins.beginGroup 'foo'
      ins.beginGroup 'bar'
      ins.send 'hello'
      ins.endGroup()
      ins.endGroup()
    it 'test reading a subgroup with threshold=1 and strip=true', (done) ->
      expected = [
        'GROUP foo'
        'OUT < bar'
        'OUT hello'
        'OUT >'
      ]
      received = []
      group.on 'data', (data) ->
        received.push "GROUP #{data}"
        return unless received.length is expected.length
        chai.expect(received).to.eql expected
        done()
      out.on 'begingroup', (group) ->
        received.push "OUT < #{group}"
      out.on 'data', (data) ->
        received.push "OUT #{data}"
        return unless received.length is expected.length
        chai.expect(received).to.eql expected
        done()
      out.on 'endgroup', (group) ->
        received.push "OUT >"
        return unless received.length is expected.length
        chai.expect(received).to.eql expected
        done()
      strip.send true
      threshold.send 1
      ins.beginGroup 'foo'
      ins.beginGroup 'bar'
      ins.send 'hello'
      ins.endGroup()
      ins.endGroup()
