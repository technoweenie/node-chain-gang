var ChainGang, Worker, events, sys;
var __slice = Array.prototype.slice;
sys = require('sys');
events = require('events');
ChainGang = function(options) {
  options || (options = {});
  this.index = {};
  this.queue = [];
  this.events = new events.EventEmitter();
  this.workers = this.build_workers(options.workers || 3);
  this.active = true;
  return this;
};
ChainGang.prototype.add = function(task, name, callback) {
  name || (name = this.default_name_for(task));
  if (callback) {
    this.events.addListener(name, callback);
  }
  if (this.index[name] !== undefined) {
    return null;
  }
  this.queue.push(name);
  this.index[name] = task;
  this.events.emit('add', name);
  return this.active ? this.perform() : null;
};
ChainGang.prototype.perform = function() {
  var _a, _b, _c, _d, worker;
  _a = []; _c = this.workers;
  for (_b = 0, _d = _c.length; _b < _d; _b++) {
    worker = _c[_b];
    if (!worker.performing) {
      return worker.perform();
    }
  }
  return _a;
};
ChainGang.prototype.shift = function() {
  var job;
  return (job = this.queue.shift()) ? {
    name: job,
    callback: this.index[job]
  } : null;
};
ChainGang.prototype.finish = function(name, err) {
  delete this.index[name];
  this.emit(name, err);
  return this.emit('finished', name, err);
};
ChainGang.prototype.emit = function(event) {
  var args;
  args = __slice.call(arguments, 1);
  return this.events.emit.apply(this.events, [event].concat(args));
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
Worker = function(chain) {
  this.chain = chain;
  this.performing = false;
  return this;
};
Worker.prototype.perform = function() {
  var data;
  if (this.performing) {
    return null;
  }
  data = this.chain.shift();
  if (!data) {
    return null;
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
exports.create = function(options) {
  return new ChainGang(options);
};