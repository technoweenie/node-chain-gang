assert    = require 'assert'
chainGang = require '../src/index'

chain = chainGang.create()

# test initial chain gang state
assert.equal 3, chain.limit
chain.active = false

# test adding an item to the queue
called = false
cb     = (name) ->
  called = true
  assert.equal 'foo',   name
  assert.equal 'work',  chain.index.foo.task

chain.addListener 'add', cb
chain.add 'work', 'foo'
assert.ok called

job = chain.index.foo
assert.equal 1, job.requests
assert.ok job.created?

assert.equal "1: foo @ 0s ago (1)", chain.checkStatus()

# test adding a duplicate item to the queue
called = false
chain.add null, 'foo'
assert.equal false, called
chain.removeListener 'add', cb
assert.equal 2, job.requests

status = chain.checkStatus()
regex  = /^1: foo \@ 0(\.\d+)?s ago \(2\)$/
assert.ok status.match(regex), "#{status} does not match #{regex}"

# test adding a 2nd item to the queue
called = false
a      =  0
job    = -> a += 1
cb     = (name) ->
  called = true
  assert.equal     'bar', name
  assert.equal     job,   chain.index.bar.task
  assert.equal     2,     chain.queue.length

chain.on 'add', cb

chain.add job, 'bar'
assert.ok called

# test finishing an item in the queue
chain.finish     chain.index.foo
assert.equal     undefined, chain.index.foo
