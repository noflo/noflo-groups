noflo = require 'noflo'

unless noflo.isBrowser()
  chai = require 'chai'
  path = require 'path'
  baseDir = path.resolve __dirname, '../'
else
  baseDir = 'noflo-groups'

describe 'ReadGroup component', ->
  c = null
  ins = null
  group = null
  loader = null

  before ->
    loader = new noflo.ComponentLoader baseDir

  beforeEach (done) ->
    @timeout 4000
    loader.load 'groups/ReadGroup', (err, instance) ->
      return done err if err
      c = instance
      ins = noflo.internalSocket.createSocket()
      group = noflo.internalSocket.createSocket()
      c.inPorts.in.attach ins
      c.outPorts.group.attach group
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
      ins.beginGroup 'foo'
      ins.send 'hello'

    it 'test reading a subgroup', (done) ->
      group.once 'data', (data) ->
        chai.expect(data).to.equal 'foo:bar'
        done()
      ins.beginGroup 'foo'
      ins.beginGroup 'bar'
      ins.send 'hello'
