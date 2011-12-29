assert    = require 'assert'
chainGang = require '../src/index'

chain = chainGang.create workers: 2
assert.equal(2, chain.limit)

timer = new Date()

called = []
job    = (worker) ->
  setTimeout ->
    called.push(worker.name)
    value = new Date()
    if worker.name == 'a' || worker.name == 'b'
      assert.ok(value - timer >= 50)
      assert.ok(value - timer <= 110)
    else
      assert.ok(value - timer >= 100)
    worker.finish()
  , 50

started = []
chain.on 'starting', (name) ->
  started.push(name)

ended = []
chain.on 'finished', (err, name) ->
  ended.push(name)

callback = ->
  ended.push 'auto'

def_name = chain.defaultNameFor job
chain.add job, 'a'
chain.add job, 'b', callback
chain.add job

process.on 'exit', ->
  assert.deepEqual ['a', 'b', def_name], called
  assert.deepEqual ['a', 'b', def_name], started
  assert.deepEqual ['a', 'auto', 'b', def_name], ended
  assert.deepEqual [], chain.listeners('b')
