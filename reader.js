#!/usr/bin/env node
// given a directory
// process every file in the directory
// store a phrase in mongo-- {raw, source_filename, metadata}

// on file
// on directory

// pos thoughts
/*

want: smallest unit of phrase that could stand alone in a poem

The brown dog smiles, not knowing whether the cat is delicious
The bag is full, necessarily, of walnuts

I used to live in the U.S.S.R. but now I live in "Amerika." Entirely wugget, she thought.

stream, add to buffer.

CHAR a-zA-Z, '()

*/

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
    this._buffer += data[c];
    if (data[c].match(/[.,;:]/)) {
      this.emit('phrase', this._buffer);
      this._buffer = '';
    }
  }
  this.emit('end');
};


function FileCrawler() {
  events.EventEmitter.call(this);
  this.on('dir', function(dir) { this.crawl(dir); });

  this.on('file', function(file) {
    files_seen++;
    console.log('file ' + file);
    var self = this;
    // TODO this might hurt but makes coding so much easier
    // TODO assumes utf
    fs.readFile(file, 'utf8', function(err, data) {
      // TODO strings are probably not efficient and buffers may help. start naive.
      // TODO feed whole file to a tokenizer
      var t = new Tokenizer();
      t.on('phrase', function(match) {
        phrases_seen++;
        var phrases = new mongodb.Collection(self.client, 'phrases');
        console.log(match);
        phrases.insert({
          'raw': match,
          'source': file
        }, function() {
          phrases_done++;
          if (files_done == files_seen && phrases_done == phrases_seen) {
            self.client.close();
          }
        });
      });
      t.on('end', function() {
        files_done++;
        console.log(files_seen, files_done, phrases_done, phrases_seen);
        if (files_done == files_seen && phrases_done == phrases_seen) {
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

var phrases_seen = 0;
var phrases_done = 0;
var files_seen = 0;
var files_done = 0;
new mongodb.Db(mongo_db, mongos, {}).open(function(err, client) {
  var fc = new FileCrawler();
  fc.client = client;
  // TODO fix this, make all relative
  process.chdir('samples');

  fc.crawl('.');
});
