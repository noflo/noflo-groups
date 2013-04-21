# TODO: Re-write test case when noflo-test supports graphs
#
# spy = require("components/Spy")
# noflo = require("noflo")

# exports.setUp = (done) ->
#   done()

# exports.tearDown = (done) ->
#   spy.clear()
#   done()

# exports["extracts the value for a group in the format of `key:value`"] = (test) ->
#   test.expect(1)

#   fbp = """
#     'graphs/HashGroupValue.fbp' -> GRAPH Graph(Graph)

#     'KEY' -> IN Graph.Key()
#     Graph.Value() OUT -> END Spy(Spy)

#     'KEY:VALUE' -> GROUP Group(Group)
#     'something' -> IN Group() OUT -> IN Clone(Clone) OUT -> IN Graph.Group()
#   """

#   noflo.graph.loadFBP fbp, (graph) ->
#     noflo.createNetwork graph, (network) ->
#       validate = ->
#         [a] = spy.getSpies()

#         unless spy.findAll(a, "data").length >= 1
#           process.nextTick(validate)
#           return

#         value = spy.find(a, "data")
#         test.equal(value, "VALUE")

#         test.done()

#       validate()
