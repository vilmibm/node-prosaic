#!/usr/bin/env node
// given a directory
// process every file in the directory
// store a phrase in mongo-- {raw, source_filename, metadata}

var events = require('events');
var fs = require('fs');
var sys = require('sys');

var mongodb = require('mongodb');

var mongo_port = 27017;
var mongo_db = 'noetry_dev';
var mongo_server = '127.0.0.1';
var mongos = new mongodb.Server(mongo_server, mongo_port, {});

function Tokenizer() {
  this._buffer = '';
  events.EventEmitter.call(this);
}
sys.inherits(Tokenizer, events.EventEmitter);
Tokenizer.prototype.write = function(data) {
  for (c in data) {
    if (data[c] === "\n" || data[c] === "\r") {
      this._buffer += ' ';
    }
    else if (data[c].match(/[.,;:]/)) {
      this._buffer += data[c];
      this.emit('phrase', this._buffer);
      this._buffer = '';
    }
    else {
      this._buffer += data[c];
    }
  }
  this.emit('end');
};


function FileCrawler() {
  events.EventEmitter.call(this);
  this.phrases_seen = 0;
  this.phrases_done = 0;
  this.files_seen = 0;
  this.files_done = 0;
  this.on('dir', function(dir) { this.crawl(dir); });

  this.on('file', function(file) {
    var self = this;
    self.files_seen++;
    // TODO this might hurt but makes coding so much easier
    // TODO assumes utf
    fs.readFile(file, 'utf8', function(err, data) {
      // TODO strings are probably not efficient and buffers may help. start naive.
      // TODO feed whole file to a tokenizer
      var t = new Tokenizer();
      t.on('phrase', function(match) {
        self.phrases_seen++;
        var phrases = new mongodb.Collection(self.client, 'phrases');
        phrases.insert({
          'raw': match,
          'source': file
        }, function() {
          self.phrases_done++;
          if (self.done()) {
            self.client.close();
          }
        });
      });
      t.on('end', function() {
        self.files_done++;
        if (self.done()) {
          self.client.close();
        }
      });
      t.write(data);
    });
  });
}

sys.inherits(FileCrawler, events.EventEmitter);

FileCrawler.prototype.crawl = function(path) {
  var self = this;
  fs.readdir(path, function(err, files) {
    files.forEach(function(x) {
      fs.stat(x, function(err, stats) {
        if (err) console.log(err);
        if (stats.isFile()) { self.emit('file', x); }
        if (stats.isDirectory()) { self.emit('dir', x); }
      });
    });
  });
};

FileCrawler.prototype.done = function() {
  return this.files_seen === this.files_done && this.phrases_seen === this.phrases_done;
}

new mongodb.Db(mongo_db, mongos, {}).open(function(err, client) {
  var fc = new FileCrawler();
  fc.client = client;
  // TODO fix this, make all relative
  process.chdir('samples');

  fc.crawl('.');
});
