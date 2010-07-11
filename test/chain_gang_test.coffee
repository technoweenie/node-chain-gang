sys:       require('sys')
assert:    require('assert')
chainGang: require('../src')

chain: chainGang.create()

# test initial chain gang state
assert.equal 0, chain.queue.length
assert.equal 3, chain.workers.length
chain.active = false

# test adding an item to the queue
called: false
cb: (name) ->
  called: true
  assert.equal 'foo',       name
  assert.equal 'work',      chain.index[name]
  assert.deepEqual ['foo'], chain.queue

chain.addListener 'add', cb
chain.add 'work', 'foo'
assert.ok called

# test adding a duplicate item to the queue
called: false
chain.add null, 'foo'
assert.equal false, called
chain.removeListener 'add', cb

# test adding a 2nd item to the queue
called: false
a: 0
job: ->
  a += 1
cb: (name) ->
  called: true
  assert.equal 'bar', name
  assert.equal job,   chain.index[name]
  assert.deepEqual ['foo', 'bar'], chain.queue

chain.addListener 'add', cb

chain.add job, 'bar'
assert.ok called

# test shifting an item from the queue
foo: chain.shift()
assert.equal('foo',  foo.name)
assert.equal('work', foo.callback)
assert.equal(foo.callback, chain.index[foo.name])
assert.deepEqual(['bar'], chain.queue)

# test finishing an item in the queue
chain.finish(foo.name)
assert.equal(undefined, chain.index[foo.name])
assert.deepEqual(['bar'], chain.queue)