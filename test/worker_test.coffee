sys:       require('sys')
assert:    require('assert')
chainGang: require('../src')

chain: chainGang.create({workers: 2})
assert.equal(2, chain.workers.length)

timer: new Date()

called: []
job: (worker) ->
  setTimeout (->
    called.push(worker.performing)
    value: new Date()
    if worker.performing == 'c'
      assert.ok(value - timer >= 100)
    else
      assert.ok(value - timer >= 50)
      assert.ok(value - timer <= 100)
    worker.finish()
    ), 50

started: []
chain.addListener 'starting', (name) ->
  started.push(name)

ended: []
chain.addListener 'finished', (name) ->
  ended.push(name)

chain.add 'a', job
chain.add 'b', job
chain.add 'c', job

process.addListener 'exit', ->
  assert.ok(called.indexOf('a') > -1)
  assert.ok(called.indexOf('b') > -1)
  assert.ok(called.indexOf('c') > -1)
  assert.ok(started.indexOf('a') > -1)
  assert.ok(started.indexOf('b') > -1)
  assert.ok(started.indexOf('c') > -1)
  assert.ok(ended.indexOf('a') > -1)
  assert.ok(ended.indexOf('b') > -1)
  assert.ok(ended.indexOf('c') > -1)