groupBy = (port, groups, func) ->
  for group in groups
    port.beginGroup group
  func port
  for group in groups
    port.endGroup() # group

describe 'CollectTree component', ->
  c = null
  ins = null
  out = null
  err = null
  level = null

  before (done) ->
    @timeout 4000
    loader = new noflo.ComponentLoader baseDir
    loader.load 'groups/CollectTree', (e, instance) ->
      return done e if e
      c = instance
      ins = noflo.internalSocket.createSocket()
      c.inPorts.in.attach ins
      done()
  beforeEach ->
    out = noflo.internalSocket.createSocket()
    err = noflo.internalSocket.createSocket()
    c.outPorts.out.attach out
    c.outPorts.error.attach err
  afterEach ->
    c.outPorts.out.detach out
    c.outPorts.error.detach err
    out = null
    err = null

  describe 'without any groups provided', ->
    it 'should send an error and no data', (done) ->
      out.on 'data', (data) ->
        done new Error 'Received unexpected data'
      err.on 'data', (data) ->
        chai.expect(data).to.be.an 'error'
        done()
      ins.send 'foo'
      ins.disconnect()

  describe 'with a single-level group', ->
    it 'should send out an object matching the one packet', (done) ->
      err.on 'data', done
      out.on 'data', (data) ->
        chai.expect(data).to.eql
          foo: 'bar'
        done()
      ins.beginGroup 'foo'
      ins.send 'bar'
      ins.endGroup()
      ins.disconnect()
    it 'should send out an object matching the two packets', (done) ->
      out.on 'data', (data) ->
        chai.expect(data).to.eql
          foo: ['bar', 'baz']
      out.on 'disconnect', ->
        done()

      ins.beginGroup 'foo'
      ins.send 'bar'
      ins.send 'baz'
      ins.endGroup()
      ins.disconnect()
    it 'should send out an object matching the two packets despite group level change', (done) ->
      out.on 'data', (data) ->
        chai.expect(data).to.eql
          foo: ['bar', 'baz']
      out.on 'disconnect', ->
        done()

      ins.beginGroup()
      ins.beginGroup 'foo'
      ins.send 'bar'
      ins.endGroup()
      ins.beginGroup 'foo'
      ins.send 'baz'
      ins.endGroup()
      ins.endGroup()

  describe 'with a multi-level group', ->
    it 'should send out an object matching the one packet', (done) ->
      out.on 'data', (data) ->
        chai.expect(data).to.eql
          baz:
            foo: 'bar'
      out.on 'disconnect', ->
        done()

      ins.beginGroup 'baz'
      ins.beginGroup 'foo'
      ins.send 'bar'
      ins.endGroup()
      ins.endGroup()
      ins.disconnect()
    it 'should send out an object matching the three packets', (done) ->
      out.on 'data', (data) ->
        chai.expect(data).to.eql
          baz: [
            foo: 'bar'
            'ping'
          ]
          hello: 'world'
      out.on 'disconnect', ->
        done()

      ins.beginGroup()
      ins.beginGroup 'baz'
      ins.beginGroup 'foo'
      ins.send 'bar'
      ins.endGroup()
      ins.send 'ping'
      ins.endGroup()
      ins.beginGroup 'hello'
      ins.send 'world'
      ins.endGroup()
      ins.endGroup()
    it 'should send out an object matching the two packets despite endgroups', (done) ->
      out.on 'data', (data) ->
        chai.expect(data).to.eql
          baz:
            foo: 'bar'
            hello: 'world'
      out.on 'disconnect', ->
        done()

      ins.beginGroup()
      ins.beginGroup 'baz'
      ins.beginGroup 'foo'
      ins.send 'bar'
      ins.endGroup()
      ins.endGroup()
      ins.beginGroup 'baz'
      ins.beginGroup 'hello'
      ins.send 'world'
      ins.endGroup()
      ins.endGroup()
      ins.endGroup()


    describe 'level param set to 1', () ->
      before ->
        level = noflo.internalSocket.createSocket()
        c.inPorts.level.attach level
      after ->
        level.send 0
        c.inPorts.level.detach level
        level = null
      groups = []
      it 'should collect inner groups only', (done) ->
        out.on 'begingroup', (group) ->
          groups.push group
        out.on 'data', (data) ->
          chai.expect(data).to.eql
            foo: 'bar'
            foo2: 'bar2'
        out.on 'disconnect', ->
          done()

        level.send 1
        level.disconnect()

        ins.beginGroup 'baz'
        ins.beginGroup 'foo'
        ins.send 'bar'
        ins.endGroup() #foo
        ins.beginGroup 'foo2'
        ins.send 'bar2'
        ins.endGroup() #foo2
        ins.endGroup() #baz
        ins.disconnect()

      it 'should forward outmost group', () ->
        chai.expect(groups).to.deep.eql [ 'baz' ]

    describe 'with group hierarchy per message', () ->
      groups = []
      it 'should put each message in right place', (done) ->
        out.on 'begingroup', (group) ->
          groups.push group
        out.on 'data', (data) ->
          chai.expect(data).to.eql
            baz:
              foo: 'bar'
              foo2: 'bar2'
              foo3: 'bar3'
        out.on 'disconnect', ->
          done()

        ins.beginGroup()
        groupBy ins, ['baz', 'foo'], () ->
          ins.send 'bar'
        groupBy ins, ['baz', 'foo2'], () ->
          ins.send 'bar2'
        groupBy ins, ['baz', 'foo3'], () ->
          ins.send 'bar3'
        ins.endGroup()

    describe 'with group hierarchy per message and level=1', () ->
      before ->
        level = noflo.internalSocket.createSocket()
        c.inPorts.level.attach level
      after ->
        level.send 0
        c.inPorts.level.detach level
        level = null
      groups = []
      it 'should put each message in right place', (done) ->
        out.on 'begingroup', (group) ->
          groups.push group
        out.on 'data', (data) ->
          chai.expect(data).to.eql
            foo: 'bar'
            foo2: 'bar2'
            foo3: 'bar3'
        out.on 'disconnect', ->
          done()

        level.send 1
        level.disconnect()

        ins.beginGroup()
        groupBy ins, ['baz', 'foo'], () ->
          ins.send 'bar'
        groupBy ins, ['baz', 'foo2'], () ->
          ins.send 'bar2'
        groupBy ins, ['baz', 'foo3'], () ->
          ins.send 'bar3'
        ins.endGroup()
