assert    = require 'assert'
chainGang = require '../src/index'

callbacks = 0
timedOut  = 0
calls     = 0
timer     = null # timer of the test

chain = chainGang.create(
  workers: 1
  timeout: 0.1
  onTimeout: ->
    timedOut += 1
    clearTimeout timer
)

# disable the chain so we can simulate long queueing times
chain.active = false

# adding a job with a ridic low timeout
chain.add (worker) ->
  console.log "you'll never see me"
  calls += 1
  worker.finish()
, 'a', (err) ->
  assert.equal "timeout", err.message
  callbacks += 1

setTimeout ->
  chain.perform()
, 110

process.on 'exit', ->
  assert.equal 0, calls
  assert.equal 1, callbacks
  assert.equal 1, timedOut
