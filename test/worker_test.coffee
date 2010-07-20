sys:       require('sys')
assert:    require('assert')
chainGang: require('../src')

chain: chainGang.create({workers: 2})
assert.equal(2, chain.workers.length)

timer: new Date()

called: []
job: (worker) ->
  setTimeout ->
    called.push(worker.performing)
    value: new Date()
    if worker.performing == 'c'
      assert.ok(value - timer >= 100)
    else
      assert.ok(value - timer >= 50)
      assert.ok(value - timer <= 110)
    worker.finish()
  , 50

started: []
chain.addListener 'starting', (name) ->
  started.push(name)

ended: []
chain.addListener 'finished', (name) ->
  ended.push(name)

def_name: 'default'
chain.addListener def_name, ->
  ended.push('c')
chain.add job, 'a'
chain.add job, 'b'
chain.add job

process.addListener 'exit', ->
  assert.deepEqual(['a', 'b', def_name], called)
  assert.deepEqual(['a', 'b', def_name], started)
  assert.deepEqual(['a', 'b', 'c', def_name], ended)