noflo = require 'noflo'

unless noflo.isBrowser()
  chai = require 'chai'
  path = require 'path'
  baseDir = path.resolve __dirname, '../'
else
  baseDir = 'noflo-groups'

describe 'GroupZip component', ->
  c = null
  group = null
  ins = null
  out = null
  before (done) ->
    @timeout 4000
    loader = new noflo.ComponentLoader baseDir
    loader.load 'groups/GroupZip', (err, instance) ->
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

  describe 'when provided with groups and packets', ->
    it 'should wrap packets in corresponding groups by position', (done) ->
      expected = [
        '< groupA'
        'DATA packetA'
        '>'
        '< groupB'
        'DATA packetB'
        '>'
        '< groupC'
        'DATA packetC'
        '>'
      ]
      received = []

      out.on 'begingroup', (grp) ->
        received.push "< #{grp}"
      out.on 'data', (data) ->
        received.push "DATA #{data}"
      out.on 'endgroup', ->
        received.push '>'
        return unless received.length is expected.length
        chai.expect(received).to.eql expected
        done()

      group.send 'groupA'
      group.send 'groupB'
      group.send 'groupC'
      ins.send 'packetA'
      ins.send 'packetB'
      ins.send 'packetC'
      ins.disconnect()
