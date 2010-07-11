sys:    require('sys')
events: require('events')

class ChainGang
  constructor: (options) ->
    if !options then options: {}
    @index:    {}
    @queue:    []
    @events:   new events.EventEmitter()
    @workers:  @buildWorkers(options.workers || 3)
    @active:   true

  add: (name, work_cb) ->
    if !work_cb
      work_cb: name
      name:    'default'
    if @index[name] != undefined then return

    @queue.push(name)
    @index[name]: work_cb
    @events.emit('add', name)
    if @active then @perform()

  perform: () ->
    for worker in @workers
      if !worker.performing 
        return worker.perform()

  shift: () ->
    if job: @queue.shift()
      {name: job, callback: @index[job]}

  finish: (name) ->
    delete @index[name]
    @emit('finished', name)

  emit: (event, args...) ->
    @events.emit(event, args...)

  addListener: (event, listener) ->
    @events.addListener(event, listener)

  removeListener: (event, listener) ->
    @events.removeListener(event, listener)

  buildWorkers: (num) ->
    arr: []
    for i in [0...num]
      arr.push(new Worker(this))
    arr

class Worker
  constructor: (chain) ->
    @chain:      chain
    @performing: false
    worker: this

  perform: () ->
    if @performing then return

    data: @chain.shift()
    if !data then return

    @performing: data.name

    @chain.emit('starting', data.name)
    try
      data.callback(this)
    catch err
      sys.puts(sys.inspect(err))
      @chain.emit('error', data.name, err)
      finish(data.name)

  finish: () ->
    @chain.finish(@performing)
    @performing: false
    @perform()

exports.create: (options) ->
  new ChainGang(options)