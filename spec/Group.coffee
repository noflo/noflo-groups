describe 'Group component', ->
  c = null
  ins = null
  group = null
  out = null
  before (done) ->
    @timeout 4000
    loader = new noflo.ComponentLoader baseDir
    loader.load 'groups/Group', (err, instance) ->
      return done err if err
      c = instance
      ins = noflo.internalSocket.createSocket()
      c.inPorts.in.attach ins
      group = noflo.internalSocket.createSocket()
      c.inPorts.group.attach group
      done()
  beforeEach ->
    out = noflo.internalSocket.createSocket()
    c.outPorts.out.attach out
  afterEach ->
    c.outPorts.out.detach out
    out = null
  describe 'receiving a single group for data', ->
    it 'should send the packet with the group', (done) ->
      expected = [
        '< foo'
        'DATA a'
        '>'
      ]
      received = []
      out.on 'begingroup', (group) ->
        received.push "< #{group}"
      out.on 'data', (data) ->
        received.push "DATA #{data}"
        return unless received.length is expected.length
        chai.expect(received).to.eql expected
        done()
      out.on 'endgroup', ->
        received.push '>'
        return unless received.length is expected.length
        chai.expect(received).to.eql expected
        done()
      group.send 'foo'
      ins.send 'a'
      ins.disconnect()
  describe 'receiving multiple groups for data', ->
    it 'should send the packet with the groups', (done) ->
      expected = [
        '< foo'
        '< bar'
        'DATA a'
        '>'
        '>'
      ]
      received = []
      out.on 'begingroup', (group) ->
        received.push "< #{group}"
      out.on 'data', (data) ->
        received.push "DATA #{data}"
        return unless received.length is expected.length
        chai.expect(received).to.eql expected
        done()
      out.on 'endgroup', ->
        received.push '>'
        return unless received.length is expected.length
        chai.expect(received).to.eql expected
        done()
      group.send 'foo:bar'
      ins.send 'a'
      ins.disconnect()
