assert = require 'assert'
chainGang = require '../src/index'

chain = chainGang.create()

# test initial chain gang state
assert.equal 3, chain.limit
chain.active = false

# test adding an item to the queue
called = false
cb = (name) ->
  called = true
  assert.equal 'foo', name
  assert.equal 'work', chain.index.foo.task

chain.on 'add', cb
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
regex = /^1: foo \@ 0(\.\d+)?s ago \(2\)$/
assert.ok status.match(regex), "#{status} does not match #{regex}"

# test adding a 2nd item to the queue with only a callback
called = false
cbCalled = false
a = 0
job = (job) ->
  a += 1
  job.finish null, 1

cb = (err, arg) ->
  cbCalled = true
  assert.equal null, err
  assert.equal 1, arg

chain.on 'add', (name) ->
  called = true
  assert.equal chain.defaultNameFor(job), name
  assert.equal job, chain.index[name].task
  assert.equal 2, chain.queue.length

chain.add job, cb
assert.ok called

# test performing and checking callbacks
assert.ok !cbCalled
assert.ok chain.index.foo

chain.perform()
assert.ok cbCalled
assert.equal undefined, chain.index.foo
