sys       = require 'sys'
assert    = require 'assert'
chainGang = require '../src/index'

chain = chainGang.create workers: 2
assert.equal 2, chain.workers.length

called_finished = false
called_named    = false

chain.addListener 'finished', (name, err) ->
  assert.ok err
  assert.equal 'foo', name
  called_finished = true

chain.addListener 'foo', (err) ->
  assert.ok err
  called_named = true

chain.add ->
  a.b == c
, 'foo'

process.addListener 'exit', ->
  assert.ok called_finished
  assert.ok called_named