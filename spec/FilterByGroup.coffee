describe 'FilterByGroup component', ->
  c = null
  regexp = null
  ins = null
  group = null
  out = null
  before (done) ->
    @timeout 4000
    loader = new noflo.ComponentLoader baseDir
    loader.load 'groups/FilterByGroup', (err, instance) ->
      return done err if err
      c = instance
      regexp = noflo.internalSocket.createSocket()
      ins = noflo.internalSocket.createSocket()
      c.inPorts.regexp.attach regexp
      c.inPorts.in.attach ins
      done()
  beforeEach ->
    group = noflo.internalSocket.createSocket()
    c.outPorts.group.attach group
    out = noflo.internalSocket.createSocket()
    c.outPorts.out.attach out
  afterEach ->
    c.outPorts.group.detach group
    c.outPorts.out.detach out

  describe 'with single-level groups', ->
    it 'should only send content with matching top-level group', (done) ->
      groupReceived = false
      dataReceived = false

      group.on 'data', (data) ->
        chai.expect(data).to.equal 'abc'
        groupReceived = true
        done() if dataReceived

      out.on 'data', (data) ->
        chai.expect(data).to.equal 1
        dataReceived = true
        done() if groupReceived

      regexp.send 'a.+'

      ins.connect()
      ins.beginGroup 'abc'
      ins.send 1
      ins.endGroup()
      ins.beginGroup 'pqr'
      ins.send 2
      ins.endGroup()
      ins.beginGroup 'xyz'
      ins.send 3
      ins.endGroup()
      ins.disconnect()

  describe 'with nested groups', ->
    it 'should also send sub-groups', (done) ->
      groupReceived = false
      dataReceived = false
      expected = [
        1
        3
      ]
      groups = []

      group.on 'data', (data) ->
        chai.expect(data).to.equal 'abc'
        groupReceived = true
        done() if dataReceived

      out.on 'begingroup', (grp) ->
        groups.push grp
      out.on 'data', (data) ->
        chai.expect(data).to.equal expected.shift()
        return unless expected.length is 0
        chai.expect(groups).to.eql ['xyz']
        dataReceived = true
      out.on 'endgroup', ->
        groups.pop()
        done() if groupReceived and dataReceived

      regexp.send 'a.+'

      ins.connect()
      ins.beginGroup 'abc'
      ins.send 1
      ins.beginGroup 'xyz'
      ins.send 3
      ins.endGroup()
      ins.endGroup()
      ins.beginGroup 'pqr'
      ins.send 2
      ins.endGroup()
      ins.disconnect()
