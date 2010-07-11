sys:    require('sys')
events: require('events')

# Manages the queue of callbacks.
class ChainGang
  # Initializes a ChainGang instance, and a few Worker instances.
  #
  # options - Options Hash.
  #           workers - Number of workers to create (default: 3)
  #
  # Returns ChainGang instance.
  constructor: (options) ->
    options: or {}
    @index:     {}
    @queue:     []
    @events:    new events.EventEmitter()
    @workers:   @buildWorkers(options.workers || 3)
    @active:    true

  # Public: Queues a callback in the ChainGang.
  #
  # callback - The Function to be queued.  Must take a single 'worker' arg,
  #            and it must call worker.finish() when complete.
  # name     - Optional String identifier for the job.  If you don't want 
  #            multiple copies of a job queued at the same time, give them
  #            the same name.
  #
  # Returns nothing.
  # Emits ('add', name)
  add: (callback, name) ->
    name ||= 'default'
    if @index[name] != undefined then return

    @queue.push name
    @index[name]: callback
    @events.emit 'add', name
    if @active then @perform()

  # Public: Attempts to find an idle worker to perform a job.
  #
  # Returns nothing.
  perform: ->
    for worker in @workers
      if !worker.performing 
        return worker.perform()

  # Public: Shifts the oldest job from the queue.  Workers take this to start 
  # performing the job.  The ChainGang still has a reference to the job, 
  # so identically named jobs won't be queued while it's running.
  #
  # Returns Object:
  #   name     - The unique String job identifier.
  #   callback - The job's Function.
  shift: ->
    if job: @queue.shift()
      {name: job, callback: @index[job]}

  # Public: Marks this job completed by name.
  #
  # name - The unique String job identifier.
  #
  # Returns nothing.
  # Emits ('finished', name)
  finish: (name) ->
    delete @index[name]
    @emit 'finished', name

  emit: (event, args...) ->
    @events.emit event, args...

  addListener: (event, listener) ->
    @events.addListener event, listener

  removeListener: (event, listener) ->
    @events.removeListener event, listener

  buildWorkers: (num) ->
    arr: []
    for i in [0...num]
      arr.push new Worker(this)
    arr

class Worker
  constructor: (chain) ->
    @chain:      chain
    @performing: false
    worker: this

  # If this Worker instance is idle, grab a job from the ChainGang and start it.
  #
  # Returns nothing.
  # Emits ('starting', name)
  # Emits ('error', name, err) if the callback raises an exception.
  perform: ->
    if @performing then return

    data: @chain.shift()
    if !data then return

    @performing: data.name

    @chain.emit 'starting', data.name
    try
      data.callback this
    catch err
      sys.puts sys.inspect(err)
      @chain.emit 'error', data.name, err
      finish data.name

  # Finishes the current job, and looks for another.
  #
  # Returns nothing.
  finish: ->
    @chain.finish @performing
    @performing: false
    @perform()

# Initializes a ChainGang instance, and a few Worker instances.
#
# options - Options Hash.
#           workers - Number of workers to create (default: 3)
#
# Returns ChainGang instance.
exports.create: (options) ->
  new ChainGang(options)