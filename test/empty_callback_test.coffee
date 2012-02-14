assert = require 'assert'
chainGang = require '../src/index'

calls = []
onEmpty = false
chain = chainGang.create onEmpty: -> onEmpty = true

task = -> assert.fail(onEmpty)
chain.add(task, 'a', -> calls.push(1))
chain.add(task, 'a', -> calls.push(2))
chain.add(task, 'b', -> calls.push(3))
chain.perform()

process.on 'exit', ->
  assert.deepEqual [1,2,3], calls
  assert.ok onEmpty
