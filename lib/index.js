var ChainGang, events, sys;
sys = require('sys');
events = require('events');
ChainGang = function(options) {
  this.workers = this.workers || 3;
  this.index = {};
  this.queue = [];
  this.events = new events.EventEmitter();
  return this;
};
ChainGang.prototype.add = function(name, work_cb) {
  if (this.index[name] !== undefined) {
    return null;
  }
  this.queue.push(name);
  this.index[name] = work_cb;
  return this.events.emit('add', name);
};
ChainGang.prototype.shift = function() {
  var name;
  name = this.queue.shift();
  return this.index[name];
};
ChainGang.prototype.addListener = function(event, listener) {
  return this.events.addListener(event, listener);
};
ChainGang.prototype.removeListener = function(event, listener) {
  return this.events.removeListener(event, listener);
};

exports.create = function(options) {
  return new ChainGang(options);
};