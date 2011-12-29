assert    = require 'assert'
chainGang = require '../src/index'

chain = chainGang.create workers: 2
assert.equal 2, chain.limit

called_finished = false
called_callback = false

chain.on 'finished', (err, name) ->
  assert.ok err
  assert.equal 'foo', name
  called_finished = true

chain.add (worker) ->
  a.b == c
  called_callback = true
, 'foo'

process.on 'exit', ->
  assert.ok called_finished
  assert.equal false, called_callback
