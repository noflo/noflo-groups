noflo = require 'noflo'

unless noflo.isBrowser()
  chai = require 'chai'
  path = require 'path'
  validateUuid = require 'uuid-validate'
  baseDir = path.resolve __dirname, '../'
else
  baseDir = 'noflo-groups'
  validateUuid = null

describe 'GenerateGroup component', ->
  c = null
  ins = null
  out = null
  before (done) ->
    @timeout 4000
    loader = new noflo.ComponentLoader baseDir
    loader.load 'groups/GenerateGroup', (err, instance) ->
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

  describe 'with a non-grouped packet', ->
    it 'should wrap it in a generated group', (done) ->
      groups = []
      out.on 'begingroup', (group) ->
        groups.push group
      out.on 'data', (data) ->
        chai.expect(data).to.equal 'data'
        chai.expect(groups.length).to.equal 1
        if validateUuid
          valid = validateUuid groups[0]
          chai.expect(valid, 'UUID is valid').to.equal true
      out.on 'endgroup', ->
        groups.pop()
        done() unless groups.length

      ins.send 'data'
      ins.disconnect()
      
  describe 'with a grouped packet', ->
    it 'should wrap it in a generated group', (done) ->
      groups = []
      out.on 'begingroup', (group) ->
        groups.push group
      out.on 'data', (data) ->
        chai.expect(data).to.equal 'data'
        chai.expect(groups.length).to.equal 2
        chai.expect(groups[0]).to.equal 'group'
        if validateUuid
          valid = validateUuid groups[1]
          chai.expect(valid, 'UUID is valid').to.equal true
      out.on 'endgroup', ->
        groups.pop()
        done() unless groups.length

      ins.beginGroup 'group'
      ins.send 'data'
      ins.endGroup()
      ins.disconnect()
      
  describe 'with nested groups', ->
    it 'should wrap each packet in a generated group', (done) ->
      expected = [
        '< group1'
        '< UUID'
        'data1'
        '< group2'
        '< UUID'
        'data2'
        '>'
        '>'
        '>'
        '>'
      ]
      received = []

      out.on 'begingroup', (group) ->
        received.push "< #{group}"
      out.on 'data', (data) ->
        received.push "DATA #{data}"
      out.on 'endgroup', ->
        received.push '>'
      out.on 'disconnect', ->
        for packet in expected
          recv = received.shift()
          if packet is '< UUID'
            value = recv.substr 2
            if validateUuid
              valid = validateUuid value
              chai.expect(valid, 'UUID is valid').to.equal true
            continue
          chai.expect(recv).to.equal packet
        done()

      ins.beginGroup 'group1'
      ins.send 'data1'
      ins.beginGroup 'group2'
      ins.send 'data2'
      ins.endGroup()
      ins.endGroup()
      ins.disconnect()
