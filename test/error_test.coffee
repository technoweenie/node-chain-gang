sys:       require('sys')
assert:    require('assert')
chainGang: require('../src')

chain: chainGang.create({workers: 2})
assert.equal(2, chain.workers.length)

called_finished: false
called_named: false
called_error: false
called_custom_error: false

chain.addListener 'finished', (name, err) ->
  assert.ok err
  assert.equal 'foo', name
  called_finished: true

chain.addListener 'foo', (err) ->
  assert.ok err
  called_named: true

chain.addListener 'error', (err, name) ->
  assert.ok err
  assert.equal 'foo', name
  called_error: true

chain.addListener 'error-foo', (err) ->
  assert.ok err
  called_custom_error: true

chain.add ->
  a.b == c
, 'foo'

process.addListener 'exit', ->
  assert.ok called_error
  assert.ok called_custom_error
  assert.ok called_finished
  assert.ok called_named