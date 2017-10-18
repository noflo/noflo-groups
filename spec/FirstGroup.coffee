noflo = require 'noflo'

unless noflo.isBrowser()
  chai = require 'chai'
  path = require 'path'
  baseDir = path.resolve __dirname, '../'
else
  baseDir = 'noflo-groups'

describe 'FirstGroup component', ->
  c = null
  ins = null
  out = null
  before (done) ->
    @timeout 4000
    loader = new noflo.ComponentLoader baseDir
    loader.load 'groups/FirstGroup', (err, instance) ->
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
    out = null
  describe 'receiving an un-bracketed packet', ->
    it 'should send it out as-is', (done) ->
      expected = [
        'DATA a'
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
      ins.send 'a'
  describe 'receiving a stream', ->
    it 'should send it out as-is', (done) ->
      expected = [
        '< foo'
        'DATA a'
        'DATA b'
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
      ins.beginGroup 'foo'
      ins.send 'a'
      ins.send 'b'
      ins.endGroup()
  describe 'receiving a stream with substreams', ->
    it 'should flatten the stream to one level', (done) ->
      expected = [
        '< foo'
        'DATA a'
        'DATA b'
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
      ins.beginGroup 'foo'
      ins.beginGroup 'bar'
      ins.beginGroup 'baz'
      ins.send 'a'
      ins.endGroup()
      ins.send 'b'
      ins.endGroup()
      ins.endGroup()
