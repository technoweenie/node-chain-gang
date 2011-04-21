Events = require 'events'

# Manages the queue of callbacks.
class ChainGang extends Events.EventEmitter
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
  # Returns the String name of the added job.
  # Emits ('add', name) on the ChainGang instance.
  add: (task, name, callback) ->
    name ||= @defaultNameFor task

    job = @index[name]

    if !job
      job = @index[name] = new exports.Job @, name, task
      @queue.push job
      @emit 'add', job.name

    if callback
      job.callbacks.push callback


    if @active then @perform()

  # Public: Attempts to find an idle worker to perform a job.
  #
  # Returns nothing.
  perform: ->
    while @current < @limit and @queue.length > 0
      @queue.shift().perform()

  # Public: Marks the given job completed.
  #
  # job - The completed Job.
  #
  # Returns nothing.
  # Emits ('finished', name, err) on the ChainGang instance.
  finish: (job, err) ->
    @current -= 1
    @emit 'finished', job.name, err
    delete @index[job.name]
    delete job

    if @active then @perform()

  # Generates a default name for this Job by getting the MD5 hash of the task
  # function.
  #
  # Returns a String MD5 hex digest to be used as the name for this Job.
  defaultNameFor: (task) ->
    @crypto ||= require 'crypto'
    @crypto.createHash('md5').update(task.toString()).digest('hex')

class Job
  constructor: (@chain, @name, @task) ->
    @callbacks = []

  # Performs the Job, running any callbacks.  See finish().
  #
  # Returns nothing.
  # Emits ('starting', name) on the ChainGang instance.
  perform: ->
    @chain.current += 1
    @chain.emit 'starting', @name

    try
      @task @
    catch err
      @finish err

  # Finishes the current job, and looks for another.  Any Job callbacks are
  # called with the error (if any), and any other arguments.
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

exports.ChainGang = ChainGang
exports.Job       = Job
