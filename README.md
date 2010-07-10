# Chain Gang

Chain Gang is a small in-process Node.js queue.  It ensures a limit to the number of simultaneous tasks in action at any time.  

    var chainGang = require('chaingang')
    var chain     = chainGang.create({workers: 3})

    chain.add('foo', workCallback)
    chain.add('bar', workCallback)
    chain.add('baz', workCallback)
    chain.add('qux', workCallback) // waits until one finishes

    chain.addListener('finished', function(name, value) {
      sys.puts(name + " has finished, leaving us with " + sys.inspect(value))
    })

## Use Case

Let's say you have an expensive child process to run when requests come in.  If traffic is really busy, you don't want to spin up 50 of these at once.  Also, you don't want identical child processes running.  If multiple requests want the same thing, assume they'll all get notified when it's finished.

## TODO

* Um, finish the lib.

## NOT TODO

* Persistence
* Single Process Durability

If you need anything more, use a real queue (like Resque) backed by a persistent data store.

## Development

Run this in the main directory to compile coffeescript to javascript as you go:

    coffee -wc -o lib --no-wrap src/**/*.coffee

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
