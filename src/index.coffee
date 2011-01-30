sys    = require 'sys'
events = require 'events'

# Manages the queue of callbacks.
class ChainGang
  # Initializes a ChainGang instance, and a few Worker instances.
  #
  # options - Options Hash.
  #           workers - Number of workers to create (default: 3)
  #
  # Returns ChainGang instance.
  constructor: (options) ->
    options ||= {}
    @index    = {}
    @queue    = []
    @events   = new events.EventEmitter
    @workers  = @build_workers options.workers || 3
    @active   = true

  # Public: Queues a callback in the ChainGang.
  #
  # task     - The Function to be queued.  Must take a single 'worker' arg,
  #            and it must call worker.finish() when complete.
  # name     - Optional String identifier for the job.  If you don't want 
  #            multiple copies of a job queued at the same time, give them
  #            the same name.
  # callback - Optional Function callback to run after the task completes.  This
  #            is called regardless if the task is already queued or not.
  #
  # Returns nothing.
  # Emits ('add', name)
  add: (task, name, callback) ->
    name ||= @default_name_for task

    if @index[name] != undefined then return
    if callback then @events.addListener name, callback

    @queue.push    name
    @index[name] = task
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
    if job = @queue.shift()
      {name: job, callback: @index[job]}

  # Public: Marks this job completed by name.
  #
  # name - The unique String job identifier.
  #
  # Returns nothing.
  # Emits (name, err)
  # Emits ('finished', name, err)
  finish: (name, err) ->
    delete @index[name]
    @emit name, err
    @emit 'finished', name, err

  emit: (event, args...) ->
    @events.emit event, args...

  on: (event, listener) ->
    @events.on event, listener

  addListener: (event, listener) ->
    @events.addListener event, listener

  removeListener: (event, listener) ->
    @events.removeListener event, listener

  listeners: (event) ->
    @events.listeners event

  build_workers: (num) ->
    arr = []
    for i in [0...num]
      arr.push new Worker(this)
    arr

  default_name_for: (task) ->
    @crypto ||= require 'crypto'
    @crypto.createHash('md5').update(task.toString()).digest('hex')

class Worker
  constructor: (chain) ->
    @chain      = chain
    @performing = false

  # If this Worker instance is idle, grab a job from the ChainGang and start it.
  #
  # Returns nothing.
  # Emits ('starting', name)
  # Emits ('error', err, name) if the callback raises an exception.
  perform: ->
    if @performing then return

    data = @chain.shift()
    if !data then return

    @performing = data.name

    @chain.emit 'starting', data.name
    try
      data.callback this
    catch err
      @finish data.name, err

  # Finishes the current job, and looks for another.
  #
  # Returns nothing.
  finish: (err) ->
    @chain.finish @performing, err
    @performing = false
    @perform()

# Initializes a ChainGang instance, and a few Worker instances.
#
# options - Options Hash.
#           workers - Number of workers to create (default: 3)
#
# Returns ChainGang instance.
exports.create = (options) ->
  new ChainGang(options)
