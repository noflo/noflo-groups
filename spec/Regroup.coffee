noflo = require 'noflo'

unless noflo.isBrowser()
  chai = require 'chai'
  path = require 'path'
  baseDir = path.resolve __dirname, '../'
else
  baseDir = 'noflo-groups'

describe 'Regroup component', ->
  c = null
  group = null
  ins = null
  out = null
  before (done) ->
    @timeout 4000
    loader = new noflo.ComponentLoader baseDir
    loader.load 'groups/Regroup', (err, instance) ->
      return done err if err
      c = instance
      group = noflo.internalSocket.createSocket()
      ins = noflo.internalSocket.createSocket()
      c.inPorts.group.attach group
      c.inPorts.in.attach ins
      done()
  beforeEach ->
    out = noflo.internalSocket.createSocket()
    c.outPorts.out.attach out
  afterEach ->
    c.outPorts.out.detach out

  describe 'with a grouped connection without control packets', ->
    it 'should remove all groups', (done) ->
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

      ins.beginGroup 'group'
      ins.send 'data'
      ins.endGroup()
      ins.disconnect()

  describe 'with replacement groups', ->
    it 'should replace the groups around the packet', (done) ->
      expected = [
        '< group1'
        '< group2'
        '< group3'
        'DATA data'
        '>'
        '>'
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

      group.send 'group1'
      group.send 'group2'
      group.send 'group3'
      ins.beginGroup 'group'
      ins.send 'data'
      ins.endGroup()
      ins.disconnect()
