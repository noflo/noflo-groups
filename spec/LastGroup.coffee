describe 'LastGroup component', ->
  c = null
  ins = null
  out = null
  before (done) ->
    @timeout 4000
    loader = new noflo.ComponentLoader baseDir
    loader.load 'groups/LastGroup', (err, instance) ->
      return done err if err
      c = instance
      ins = noflo.internalSocket.createSocket()
      c.inPorts.in.attach ins
      done()
  beforeEach ->
    out = noflo.internalSocket.createSocket()
    c.outPorts.out.attach out
  afterEach ->
    c.outPorts.out.detach out

  describe 'when receiving no groups', ->
    it 'should send packet as-is', (done) ->
      expected = [
        'DATA data'
      ]
      received = []

      out.on 'begingroup', (grp) ->
        received.push "< #{grp}"
      out.on 'data', (data) ->
        received.push "DATA #{data}"
      out.on 'endgroup', ->
        received.push '>'
      out.on 'disconnect', ->
        chai.expect(received).to.eql expected
        done()

      ins.send 'data'
      ins.disconnect()

  describe 'when receiving a single group', ->
    it 'should send one group', (done) ->
      expected = [
        '< group'
        'DATA data'
        '>'
      ]
      received = []

      out.on 'begingroup', (grp) ->
        received.push "< #{grp}"
      out.on 'data', (data) ->
        received.push "DATA #{data}"
      out.on 'endgroup', ->
        received.push '>'
      out.on 'disconnect', ->
        chai.expect(received).to.eql expected
        done()

      ins.beginGroup 'group'
      ins.send 'data'
      ins.endGroup()
      ins.disconnect()

  describe 'when receiving two nested groups', ->
    it 'should send one group', (done) ->
      expected = [
        '< group2'
        'DATA data'
        '>'
      ]
      received = []

      out.on 'begingroup', (grp) ->
        received.push "< #{grp}"
      out.on 'data', (data) ->
        received.push "DATA #{data}"
      out.on 'endgroup', ->
        received.push '>'
      out.on 'disconnect', ->
        chai.expect(received).to.eql expected
        done()

      ins.beginGroup 'group1'
      ins.beginGroup 'group2'
      ins.send 'data'
      ins.endGroup()
      ins.endGroup()
      ins.disconnect()
    it 'should send one group around two IPs', (done) ->
      expected = [
        '< group2'
        'DATA data1'
        'DATA data2'
        '>'
      ]
      received = []

      out.on 'begingroup', (grp) ->
        received.push "< #{grp}"
      out.on 'data', (data) ->
        received.push "DATA #{data}"
      out.on 'endgroup', ->
        received.push '>'
      out.on 'disconnect', ->
        chai.expect(received).to.eql expected
        done()

      ins.beginGroup 'group1'
      ins.beginGroup 'group2'
      ins.send 'data1'
      ins.send 'data2'
      ins.endGroup()
      ins.endGroup()
      ins.disconnect()
