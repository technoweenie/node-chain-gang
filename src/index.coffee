sys:    require('sys')
events: require('events')

class ChainGang
  constructor: (options) ->
    @workers:  this.workers || 3
    @index:    {}
    @queue:    []
    @events:   new events.EventEmitter()

  add: (name, work_cb) ->
    if @index[name] != undefined then return

    @queue.push(name)
    @index[name]: work_cb
    @events.emit('add', name)

  shift: () ->
    name: @queue.shift()
    {"name": name, callback: @index[name]}

  finish: (name) ->
    delete @index[name]

  addListener: (event, listener) ->
    @events.addListener(event, listener)

  removeListener: (event, listener) ->
    @events.removeListener(event, listener)

exports.create: (options) ->
  new ChainGang(options)