# Chain Gang

Chain Gang is a small in-process Node.js queue.  It ensures a limit to the
number of simultaneous tasks in action at any time.

First, set up a Chain Gang, and specify the number of workers.

    var chainGang = require('chaingang')
    var chain     = chainGang.create({workers: 3})

Now, write a function to do some work.

    var task = function(worker) {
      // do some work
      var err;
      try {
        // do some work
      catch(e) {
        err = e
      }
      worker.finish(err, 1, 2, 3) // and call this when finished
    }

You can add it add it to the Chain Gang and have it completed when there
is an open slot.

    chain.add(task);

You can also give the task a unique identifier.  If you have multiple
requests for the same task to complete, this ensures that the actual
work is only done a single time.

    chain.add(task, 'bar')
    chain.add(task, 'bar')

Finally, you can specify the callback to run after the task completes.

    chain.add(task, 'bar', function(err, a, b, c) {
      // this optional callback is called with err, and any other arguments
      // sent to worker.finish() above.
    })

The Chain Gang instance also has a few higher level events so you can
watch the status of jobs entering and exiting the chain.

    chain.on('add', function(name) {
      console.log(name, "has been queued.")
    })

    chain.on('starting', function(name) {
      console.log(name, "has started running.")
    })

    chain.on('finished', function(err, name) {
      console.log(name, "has finished.  Error:", err)
    })

## Use Case

Let's say you have an expensive child process to run when requests come in.
If traffic is really busy, you don't want to spin up 50 of these at once.
Also, you don't want identical child processes running.  If multiple requests
want the same thing, assume they'll all get notified when it's finished.

## NOT TODO

* Persistence
* Single Process Durability

If you need anything more, use a real queue (like Resque) backed by a
persistent data store.

## Development

Run this to compile coffeescript to javascript as you go:

    make dev

## Note on Patches/Pull Requests

* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with version or history.
  (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

## Copyright

Copyright (c) 2010 rick. See LICENSE for details.
