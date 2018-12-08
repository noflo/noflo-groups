describe 'Objectify component', ->
  c = null
  regexp = null
  ins = null
  out = null
  before (done) ->
    @timeout 4000
    loader = new noflo.ComponentLoader baseDir
    loader.load 'groups/Objectify', (err, instance) ->
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
    it 'should make an object and retain groups', (done) ->
      groups = []
      out.on 'begingroup', (grp) ->
        groups.push grp
      out.on 'data', (data) ->
        chai.expect(data).to.eql
          a: 'whatever'
        chai.expect(groups).to.eql [
          'abc'
        ]
      out.on 'endgroup', ->
        groups.pop()
        done() unless groups.length

      regexp.send '^(a)'
      ins.beginGroup 'abc'
      ins.send 'whatever'
      ins.endGroup()

  describe 'with groups not matching regexp', ->
    it 'should send packet as-is and retain groups', (done) ->
      groups = []
      out.on 'begingroup', (grp) ->
        groups.push grp
      out.on 'data', (data) ->
        chai.expect(data).to.equal 'whatever'
        chai.expect(groups).to.eql [
          'xyz'
        ]
      out.on 'endgroup', ->
        groups.pop()
        done() unless groups.length

      regexp.send '^(a)'
      ins.beginGroup 'xyz'
      ins.send 'whatever'
      ins.endGroup()
