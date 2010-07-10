sys:       require('sys')
assert:    require('assert')
chainGang: require('../src')

chain: chainGang.create()

# test initial chain gang state
assert.equal(0, chain.queue.length)
assert.equal(3, chain.workers)

# test adding an item to the queue
called: false
chain.addListener 'add', (name) ->
  called: true
  assert.equal('foo',       name)
  assert.equal('work!',     chain.index[name])
  assert.deepEqual(['foo'], chain.queue)

chain.add('foo', 'work!')
assert.ok(called)

# test adding a duplicate item to the queue
called: false
chain.add('foo')
assert.equal(false, called)