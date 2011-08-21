#!/usr/bin/env node
// given a directory
// process every file in the directory
// store a line in mongo-- {raw, source_filename, metadata}

// on file
// on directory

var events = require('events');
var fs = require('fs');
var sys = require('sys');

var mongodb = require('mongodb');

var mongo_port = 27017;
var mongo_db = 'noetry_dev';
var mongo_server = '127.0.0.1';
var mongos = new mongodb.Server(mongo_server, mongo_port, {});

function FileCrawler() {
  events.EventEmitter.call(this);
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

new mongodb.Db(mongo_db, mongos, {}).open(function(err, client) {
  var lines_seen = 0;
  var lines_done = 0;
  var files_seen = 0;
  var files_done = 0;
  var fc = new FileCrawler();
  fc.on('dir', function(dir) { this.crawl(dir); });

  fc.on('file', function(file) {
    files_seen++;
    console.log('file ' + file);
    var self = this;
    // TODO this might hurt but makes coding so much easier
    // TODO assumes utf
    fs.readFile(file, 'utf8', function(err, data) {
      // TODO strings are probably not efficient and buffers may help. start naive.
      // TODO feed whole file to a tokenizer
      data.split('.').forEach(function(x) {
        lines_seen++;
        self.emit('line', file, x);
      });
      files_done++;
      if (files_seen == files_done) {
        if (lines_seen == lines_done) {
          client.close();
        }
      }
    });
  });

  fc.on('line', function(file, line) {
    var lines = new mongodb.Collection(client, 'lines');
    // TODO collect metadata
    lines.insert({
      'raw': line,
      'source': file
    });
    lines_done++;
  });

  // TODO fix this, make all relative
  process.chdir('samples');

  fc.crawl('.');
});
