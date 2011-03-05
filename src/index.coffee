sys    = require 'sys'
events = require 'events'

# Manages the queue of callbacks.
class ChainGang extends events.EventEmitter
  # Initializes a ChainGang instance, and a few Worker instances.
  #
  # options - Options Hash.
  #           workers - Number of workers to create (default: 3)
  #
  # Returns ChainGang instance.
  constructor: (options) ->
    options or= {}
    @queue    = []
    @current  = 0
    @limit    = options.workers or 3
    @index    = {} # name: worker
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

    worker = @index[name]

    if !worker
      worker = @index[name] = new Worker @, name, task
      @queue.push worker
      @emit 'add', worker.name

    if callback
      worker.callbacks.push callback


    if @active then @perform()

  # Public: Attempts to find an idle worker to perform a job.
  #
  # Returns nothing.
  perform: ->
    while @current < @limit and @queue.length > 0
      @queue.shift().perform()

  # Public: Marks this job completed by name.
  #
  # name - The unique String job identifier.
  #
  # Returns nothing.
  # Emits ('finished', name, err)
  finish: (worker, err) ->
    @current -= 1
    @emit 'finished', worker.name, err
    delete @index[worker.name]
    delete worker
    if @active then @perform()

  default_name_for: (task) ->
    @crypto ||= require 'crypto'
    @crypto.createHash('md5').update(task.toString()).digest('hex')

class Worker
  constructor: (@chain, @name, @task) ->
    @callbacks = []

  # If this Worker instance is idle, grab a job from the ChainGang and start it.
  #
  # Returns nothing.
  # Emits ('starting', name)
  # Emits ('error', err, name) if the callback raises an exception.
  perform: ->
    @chain.current += 1
    @chain.emit 'starting', @name

    try
      @task @
    catch err
      @finish err

  # Finishes the current job, and looks for another.
  #
  # Returns nothing.
  finish: (err, args...) ->
    @callbacks.forEach (cb) ->
      cb err, args...
    @chain.finish @, err

# Initializes a ChainGang instance, and a few Worker instances.
#
# options - Options Hash.
#           workers - Number of workers to create (default: 3)
#
# Returns ChainGang instance.
exports.create = (options) ->
  new ChainGang(options)
