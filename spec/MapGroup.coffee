noflo = require 'noflo'

unless noflo.isBrowser()
  chai = require 'chai'
  path = require 'path'
  baseDir = path.resolve __dirname, '../'
else
  baseDir = 'noflo-groups'

describe 'MapGroup component', ->
  c = null
  regexp = null
  map = null
  ins = null
  out = null
  before (done) ->
    @timeout 4000
    loader = new noflo.ComponentLoader baseDir
    loader.load 'groups/MapGroup', (err, instance) ->
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
  describe 'with a group map', ->
    before ->
      map = noflo.internalSocket.createSocket()
      c.inPorts.map.attach map
    after ->
      c.inPorts.map.detach map
      map = null
    it 'should send ungrouped data as-is', (done) ->
      expected = [
        'DATA foo'
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
      map.send 'foo=bar'
      ins.send 'foo'
    it 'should send unmatched data as-is', (done) ->
      expected = [
        '< bar'
        'DATA foo'
        'DATA bar'
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
      map.send 'foo=bar'
      ins.beginGroup 'bar'
      ins.send 'foo'
      ins.send 'bar'
      ins.endGroup()
    it 'should send matched data replaced group', (done) ->
      expected = [
        '< bar'
        'DATA foo'
        'DATA bar'
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
      map.send 'foo=bar'
      ins.beginGroup 'foo'
      ins.send 'foo'
      ins.send 'bar'
      ins.endGroup()
    it 'should send matched data replaced group with map object', (done) ->
      expected = [
        '< bar'
        'DATA foo'
        'DATA bar'
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
      map.send
        foo: 'bar'
      ins.beginGroup 'foo'
      ins.send 'foo'
      ins.send 'bar'
      ins.endGroup()
  describe 'with a group regexp', ->
    before ->
      regexp = noflo.internalSocket.createSocket()
      c.inPorts.regexp.attach regexp
    after ->
      c.inPorts.regexp.detach regexp
      regexp = null
    it 'should send ungrouped data as-is', (done) ->
      expected = [
        'DATA foo'
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
      regexp.send 'f.+=bar'
      ins.send 'foo'
    it 'should send unmatched data as-is', (done) ->
      expected = [
        '< bar'
        'DATA foo'
        'DATA bar'
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
      regexp.send 'f.+=bar'
      ins.beginGroup 'bar'
      ins.send 'foo'
      ins.send 'bar'
      ins.endGroup()
    it 'should send matched data replaced group', (done) ->
      expected = [
        '< bar'
        'DATA foo'
        'DATA bar'
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
      regexp.send 'f.+=bar'
      ins.beginGroup 'foo'
      ins.send 'foo'
      ins.send 'bar'
      ins.endGroup()
    it 'should send matched data replaced group with regexp object', (done) ->
      expected = [
        '< bar'
        'DATA foo'
        'DATA bar'
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
      regexp.send
        'f.+': 'bar'
      ins.beginGroup 'foo'
      ins.send 'foo'
      ins.send 'bar'
      ins.endGroup()
  describe 'with a group regexp with capture', ->
    before ->
      regexp = noflo.internalSocket.createSocket()
      c.inPorts.regexp.attach regexp
    after ->
      c.inPorts.regexp.detach regexp
      regexp = null
    it 'should send matched data replaced group', (done) ->
      expected = [
        '< somefile'
        'DATA foo'
        'DATA bar'
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
      regexp.send 'data\\/([a-z]+)\\.yaml=$1'
      ins.beginGroup 'data/somefile.yaml'
      ins.send 'foo'
      ins.send 'bar'
      ins.endGroup()
