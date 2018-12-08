describe 'CollectObject component', ->
  c = null
  keys = null
  allpackets = null
  collect = []
  release = null
  out = null
  before (done) ->
    @timeout 4000
    loader = new noflo.ComponentLoader baseDir
    loader.load 'groups/CollectObject', (err, instance) ->
      return done err if err
      c = instance
      keys = noflo.internalSocket.createSocket()
      c.inPorts.keys.attach keys
      collect.push noflo.internalSocket.createSocket()
      c.inPorts.collect.attach collect[0]
      collect.push noflo.internalSocket.createSocket()
      c.inPorts.collect.attach collect[1]
      release = noflo.internalSocket.createSocket()
      c.inPorts.release.attach release
      done()
  beforeEach ->
    out = noflo.internalSocket.createSocket()
    c.outPorts.out.attach out
  afterEach (done) ->
    c.outPorts.out.detach out
    out = null
    c.shutdown done
  describe 'when released', ->
    describe 'wihout brackets', ->
      it 'should send the collected object out', (done) ->
        expected = [
          {
            foo: 'hello'
            bar: 'world'
          }
        ]
        received = []
        out.on 'begingroup', (group) ->
          received.push "< #{group}"
        out.on 'data', (data) ->
          received.push data
          return unless expected.length is received.length
          chai.expect(received).to.eql expected
          done()
        out.on 'endgroup', (data) ->
          received.push '>'
          return unless expected.length is received.length
          chai.expect(received).to.eql expected
          done()
        keys.send 'foo'
        keys.send 'bar'
        collect[0].send 'goodbye'
        collect[0].send 'hello'
        collect[1].send 'world'
        release.send true
      describe 'with allpackets', ->
        before ->
          allpackets = noflo.internalSocket.createSocket()
          c.inPorts.allpackets.attach allpackets
        after ->
          c.inPorts.allpackets.detach allpackets
          allpackets = null
        it 'should send the collected object out with multiple packets in one key', (done) ->
          expected = [
            {
              foo: [
                'hello'
                'wonderful'
              ]
              bar: 'world'
            }
          ]
          received = []
          out.on 'begingroup', (group) ->
            received.push "< #{group}"
          out.on 'data', (data) ->
            received.push data
            return unless expected.length is received.length
            chai.expect(received).to.eql expected
            done()
          out.on 'endgroup', (data) ->
            received.push '>'
            return unless expected.length is received.length
            chai.expect(received).to.eql expected
            done()
          allpackets.send 'foo'
          keys.send 'foo'
          keys.send 'bar'
          collect[0].send 'hello'
          collect[0].send 'wonderful'
          collect[1].send 'world'
          release.send true
    describe 'with a single-level stream', ->
      it 'should send the collected object out', (done) ->
        expected = [
          {
            a:
              foo: 'hello'
              bar: 'world'
          }
        ]
        received = []
        out.on 'begingroup', (group) ->
          received.push "< #{group}"
        out.on 'data', (data) ->
          received.push data
          return unless expected.length is received.length
          chai.expect(received).to.eql expected
          done()
        out.on 'endgroup', (data) ->
          received.push '>'
          return unless expected.length is received.length
          chai.expect(received).to.eql expected
          done()
        keys.send 'foo'
        keys.send 'bar'
        collect[0].beginGroup 'a'
        collect[0].send 'goodbye'
        collect[0].send 'hello'
        collect[0].endGroup()
        collect[1].beginGroup 'a'
        collect[1].send 'world'
        collect[1].endGroup()
        release.send true
      describe 'with allpackets', ->
        before ->
          allpackets = noflo.internalSocket.createSocket()
          c.inPorts.allpackets.attach allpackets
        after ->
          c.inPorts.allpackets.detach allpackets
          allpackets = null
        it 'should send the collected object out with multiple packets in one key', (done) ->
          expected = [
            {
              a:
                foo: [
                  'hello'
                  'wonderful'
                ]
                bar: 'world'
            }
          ]
          received = []
          out.on 'begingroup', (group) ->
            received.push "< #{group}"
          out.on 'data', (data) ->
            received.push data
            return unless expected.length is received.length
            chai.expect(received).to.eql expected
            done()
          out.on 'endgroup', (data) ->
            received.push '>'
            return unless expected.length is received.length
            chai.expect(received).to.eql expected
            done()
          allpackets.send 'foo'
          keys.send 'foo'
          keys.send 'bar'
          collect[0].beginGroup 'a'
          collect[0].send 'hello'
          collect[0].send 'wonderful'
          collect[0].endGroup()
          collect[1].beginGroup 'a'
          collect[1].send 'world'
          collect[1].endGroup()
          release.send true
    describe 'with a substream', ->
      it 'should send the collected object out', (done) ->
        expected = [
          {
            a:
              foo: 'hello'
              bar: 'world'
          }
        ]
        received = []
        out.on 'begingroup', (group) ->
          received.push "< #{group}"
        out.on 'data', (data) ->
          received.push data
          return unless expected.length is received.length
          chai.expect(received).to.eql expected
          done()
        out.on 'endgroup', (data) ->
          received.push '>'
          return unless expected.length is received.length
          chai.expect(received).to.eql expected
          done()
        keys.send 'foo'
        keys.send 'bar'
        collect[0].beginGroup 'a'
        collect[0].send 'goodbye'
        collect[0].send 'hello'
        collect[0].endGroup()
        collect[1].beginGroup 'a'
        collect[1].beginGroup 'b'
        collect[1].send 'world'
        collect[1].endGroup()
        collect[1].endGroup()
        release.send true
      describe 'with allpackets', ->
        before ->
          allpackets = noflo.internalSocket.createSocket()
          c.inPorts.allpackets.attach allpackets
        after ->
          c.inPorts.allpackets.detach allpackets
          allpackets = null
        it 'should send the collected object out with multiple packets in one key', (done) ->
          expected = [
            {
              a:
                foo: [
                  'hello'
                  'wonderful'
                ]
                bar: 'world'
            }
          ]
          received = []
          out.on 'begingroup', (group) ->
            received.push "< #{group}"
          out.on 'data', (data) ->
            received.push data
            return unless expected.length is received.length
            chai.expect(received).to.eql expected
            done()
          out.on 'endgroup', (data) ->
            received.push '>'
            return unless expected.length is received.length
            chai.expect(received).to.eql expected
            done()
          allpackets.send 'foo'
          keys.send 'foo'
          keys.send 'bar'
          collect[0].beginGroup 'a'
          collect[0].beginGroup 'b'
          collect[0].send 'hello'
          collect[0].send 'wonderful'
          collect[0].endGroup()
          collect[0].endGroup()
          collect[1].beginGroup 'a'
          collect[1].send 'world'
          collect[1].endGroup()
          release.send true
