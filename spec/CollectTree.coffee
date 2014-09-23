noflo = require 'noflo'

unless noflo.isBrowser()
  chai = require 'chai' unless chai
  CollectTree = require '../components/CollectTree.coffee'
else
  CollectTree = require 'noflo-groups/components/CollectTree.js'

describe 'CollectTree component', ->
  c = null
  ins = null
  out = null
  err = null
  level = null

  beforeEach ->
    c = CollectTree.getComponent()
    ins = noflo.internalSocket.createSocket()
    level = noflo.internalSocket.createSocket()
    out = noflo.internalSocket.createSocket()
    err = noflo.internalSocket.createSocket()
    c.inPorts.in.attach ins
    c.inPorts.level.attach level
    c.outPorts.out.attach out
    c.outPorts.error.attach err

  describe 'without any groups provided', ->
    it 'should send an error and no data', (done) ->
      out.on 'data', (data) ->
        chai.expect(true).to.equal false

      err.on 'data', (data) ->
        chai.expect(data).to.be.an 'object'
        chai.expect(c.data).to.equal null
        chai.expect(c.collectGroups.length).to.equal 0
        chai.expect(c.forwardGroups.length).to.equal 0
        done()

      ins.send 'foo'
      ins.send 'bar'
      ins.disconnect()

  describe 'with a single-level group', ->
    it 'should send out an object matching the one packet', (done) ->
      out.on 'data', (data) ->
        chai.expect(data).to.eql
          foo: 'bar'
      out.on 'disconnect', ->
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

      ins.beginGroup 'foo'
      ins.send 'bar'
      ins.endGroup()
      ins.beginGroup 'foo'
      ins.send 'baz'
      ins.endGroup()
      ins.disconnect()

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

      ins.beginGroup 'baz'
      ins.beginGroup 'foo'
      ins.send 'bar'
      ins.endGroup()
      ins.send 'ping'
      ins.endGroup()
      ins.beginGroup 'hello'
      ins.send 'world'
      ins.endGroup()
      ins.disconnect()
    it 'should send out an object matching the two packets despite endgroups', (done) ->
      out.on 'data', (data) ->
        chai.expect(data).to.eql
          baz:
            foo: 'bar'
            hello: 'world'
      out.on 'disconnect', ->
        done()

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
      ins.disconnect()


    describe 'level param set to 1', () ->
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
