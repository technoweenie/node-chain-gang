(function() {
  var ChainGang, Worker, events, sys;
  var __slice = Array.prototype.slice;
  sys = require('sys');
  events = require('events');
  ChainGang = (function() {
    function ChainGang(options) {
      options || (options = {});
      this.index = {};
      this.queue = [];
      this.events = new events.EventEmitter;
      this.workers = this.build_workers(options.workers || 3);
      this.active = true;
    }
    ChainGang.prototype.add = function(task, name, callback) {
      name || (name = this.default_name_for(task));
      if (this.index[name] !== void 0) {
        return;
      }
      if (callback) {
        this.events.addListener(name, callback);
      }
      this.queue.push(name);
      this.index[name] = task;
      this.events.emit('add', name);
      if (this.active) {
        return this.perform();
      }
    };
    ChainGang.prototype.perform = function() {
      var worker, _i, _len, _ref;
      _ref = this.workers;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        worker = _ref[_i];
        if (!worker.performing) {
          return worker.perform();
        }
      }
    };
    ChainGang.prototype.shift = function() {
      var job;
      if (job = this.queue.shift()) {
        return {
          name: job,
          callback: this.index[job]
        };
      }
    };
    ChainGang.prototype.finish = function(name, err) {
      delete this.index[name];
      this.emit(name, err);
      return this.emit('finished', name, err);
    };
    ChainGang.prototype.emit = function() {
      var args, event, _ref;
      event = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      return (_ref = this.events).emit.apply(_ref, [event].concat(__slice.call(args)));
    };
    ChainGang.prototype.on = function(event, listener) {
      return this.events.on(event, listener);
    };
    ChainGang.prototype.addListener = function(event, listener) {
      return this.events.addListener(event, listener);
    };
    ChainGang.prototype.removeListener = function(event, listener) {
      return this.events.removeListener(event, listener);
    };
    ChainGang.prototype.listeners = function(event) {
      return this.events.listeners(event);
    };
    ChainGang.prototype.build_workers = function(num) {
      var arr, i;
      arr = [];
      for (i = 0; (0 <= num ? i < num : i > num); (0 <= num ? i += 1 : i -= 1)) {
        arr.push(new Worker(this));
      }
      return arr;
    };
    ChainGang.prototype.default_name_for = function(task) {
      this.crypto || (this.crypto = require('crypto'));
      return this.crypto.createHash('md5').update(task.toString()).digest('hex');
    };
    return ChainGang;
  })();
  Worker = (function() {
    function Worker(chain) {
      this.chain = chain;
      this.performing = false;
    }
    Worker.prototype.perform = function() {
      var data;
      if (this.performing) {
        return;
      }
      data = this.chain.shift();
      if (!data) {
        return;
      }
      this.performing = data.name;
      this.chain.emit('starting', data.name);
      try {
        return data.callback(this);
      } catch (err) {
        return this.finish(data.name, err);
      }
    };
    Worker.prototype.finish = function(err) {
      this.chain.finish(this.performing, err);
      this.performing = false;
      return this.perform();
    };
    return Worker;
  })();
  exports.create = function(options) {
    return new ChainGang(options);
  };
}).call(this);
