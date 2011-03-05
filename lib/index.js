var ChainGang, Worker, events, sys;
var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
  for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
  function ctor() { this.constructor = child; }
  ctor.prototype = parent.prototype;
  child.prototype = new ctor;
  child.__super__ = parent.prototype;
  return child;
}, __slice = Array.prototype.slice;
sys = require('sys');
events = require('events');
ChainGang = (function() {
  __extends(ChainGang, events.EventEmitter);
  function ChainGang(options) {
    options || (options = {});
    this.queue = [];
    this.current = 0;
    this.limit = options.workers || 3;
    this.index = {};
    this.active = true;
  }
  ChainGang.prototype.add = function(task, name, callback) {
    var worker;
    name || (name = this.default_name_for(task));
    worker = this.index[name];
    if (!worker) {
      worker = this.index[name] = new Worker(this, name, task);
      this.queue.push(worker);
      this.emit('add', worker.name);
    }
    if (callback) {
      worker.callbacks.push(callback);
    }
    if (this.active) {
      return this.perform();
    }
  };
  ChainGang.prototype.perform = function() {
    var _results;
    _results = [];
    while (this.current < this.limit && this.queue.length > 0) {
      _results.push(this.queue.shift().perform());
    }
    return _results;
  };
  ChainGang.prototype.finish = function(worker, err) {
    this.current -= 1;
    this.emit('finished', worker.name, err);
    delete this.index[worker.name];
    delete worker;
    if (this.active) {
      return this.perform();
    }
  };
  ChainGang.prototype.default_name_for = function(task) {
    this.crypto || (this.crypto = require('crypto'));
    return this.crypto.createHash('md5').update(task.toString()).digest('hex');
  };
  return ChainGang;
})();
Worker = (function() {
  function Worker(chain, name, task) {
    this.chain = chain;
    this.name = name;
    this.task = task;
    this.callbacks = [];
  }
  Worker.prototype.perform = function() {
    this.chain.current += 1;
    this.chain.emit('starting', this.name);
    try {
      return this.task(this);
    } catch (err) {
      return this.finish(err);
    }
  };
  Worker.prototype.finish = function() {
    var args, err;
    err = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    this.callbacks.forEach(function(cb) {
      return cb.apply(null, [err].concat(__slice.call(args)));
    });
    return this.chain.finish(this, err);
  };
  return Worker;
})();
exports.create = function(options) {
  return new ChainGang(options);
};