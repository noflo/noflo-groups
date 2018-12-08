describe 'ObjectifyByGroup component', ->
  c = null
  regexp = null
  ins = null
  out = null
  before (done) ->
    @timeout 4000
    loader = new noflo.ComponentLoader baseDir
    loader.load 'groups/ObjectifyByGroup', (err, instance) ->
      return done err if err
      c = instance
      regexp = noflo.internalSocket.createSocket()
      ins = noflo.internalSocket.createSocket()
      c.inPorts.regexp.attach regexp
      c.inPorts.in.attach ins
      done()
  beforeEach ->
    out = noflo.internalSocket.createSocket()
    c.outPorts.out.attach out
  afterEach ->
    c.outPorts.out.detach out

  describe 'with groups matching regexp', ->
    it 'should make an object and remove groups', (done) ->
      expected = [
        {
          a: 'whatever'
        }
      ]
      received = []
      out.on 'begingroup', (grp) ->
        received.push "< #{grp}"
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

      regexp.send '^(a)'
      ins.beginGroup 'abc'
      ins.send 'whatever'
      ins.endGroup()

  describe 'with groups not matching regexp', ->
    it 'should send packet as-is and retain groups', (done) ->
      expected = [
        '< xyz'
        'whatever'
        '>'
      ]
      received = []
      out.on 'begingroup', (grp) ->
        received.push "< #{grp}"
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

      regexp.send '^(a)'
      ins.beginGroup 'xyz'
      ins.send 'whatever'
      ins.endGroup()
