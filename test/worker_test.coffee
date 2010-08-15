sys       = require 'sys'
assert    = require 'assert'
chainGang = require '../src/index'

chain = chainGang.create workers: 2
assert.equal(2, chain.workers.length)

timer = new Date()

called = []
job    = (worker) ->
  setTimeout ->
    called.push(worker.performing)
    value = new Date()
    if worker.performing == 'a' || worker.performing == 'b'
      assert.ok(value - timer >= 50)
      assert.ok(value - timer <= 110)
    else
      assert.ok(value - timer >= 100)
    worker.finish()
  , 50

started = []
chain.addListener 'starting', (name) ->
  started.push(name)

ended = []
chain.addListener 'finished', (name) ->
  ended.push(name)

callback = ->
  # remove self from listeners
  @removeListener 'b', callback
  ended.push 'auto'

def_name = chain.default_name_for(job)
chain.addListener def_name, ->
  ended.push('c')
chain.add job, 'a'
chain.add job, 'b', callback
chain.add job

process.addListener 'exit', ->
  assert.deepEqual ['a', 'b', def_name], called
  assert.deepEqual ['a', 'b', def_name], started
  assert.deepEqual ['a', 'auto', 'b', 'c', def_name], ended
  assert.deepEqual [], chain.listeners('b')