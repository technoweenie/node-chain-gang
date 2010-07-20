var ChainGang, Worker, events, sys;
var __slice = Array.prototype.slice;
sys = require('sys');
events = require('events');
ChainGang = function(options) {
  options = options || {};
  this.index = {};
  this.queue = [];
  this.events = new events.EventEmitter();
  this.workers = this.build_workers(options.workers || 3);
  this.active = true;
  return this;
};
ChainGang.prototype.add = function(task, name) {
  name = name || 'default';
  if (this.index[name] !== undefined) {
    return null;
  }
  this.queue.push(name);
  this.index[name] = task;
  this.events.emit('add', name);
  if (this.active) {
    return this.perform();
  }
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
  if ((job = this.queue.shift())) {
    return {
      name: job,
      callback: this.index[job]
    };
  }
};
ChainGang.prototype.finish = function(name) {
  delete this.index[name];
  this.emit(name);
  return this.emit('finished', name);
};
ChainGang.prototype.emit = function(event) {
  var args;
  var _a = arguments.length, _b = _a >= 2;
  args = __slice.call(arguments, 1, _a - 0);
  return this.events.emit.apply(this.events, [event].concat(args));
};
ChainGang.prototype.addListener = function(event, listener) {
  return this.events.addListener(event, listener);
};
ChainGang.prototype.removeListener = function(event, listener) {
  return this.events.removeListener(event, listener);
};
ChainGang.prototype.build_workers = function(num) {
  var arr, i;
  arr = [];
  for (i = 0; i < num; i += 1) {
    arr.push(new Worker(this));
  }
  return arr;
};

Worker = function(chain) {
  var worker;
  this.chain = chain;
  this.performing = false;
  worker = this;
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
    sys.puts(sys.inspect(err));
    this.chain.emit('error', err, data.name);
    return finish(data.name);
  }
};
Worker.prototype.finish = function() {
  this.chain.finish(this.performing);
  this.performing = false;
  return this.perform();
};

exports.create = function(options) {
  return new ChainGang(options);
};