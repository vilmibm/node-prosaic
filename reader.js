// given a directory
// process every file in the directory
// store a line in mongo-- {raw, source_filename, metadata}

// on file
// on directory

var events = require('events');
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

FileCrawler.prototype.extend = function(obj) {
  for (x in obj) { if (obj.hasOwnProperty(x)) this.prototype['x'] = obj[x] }
};

FileCrawler.extend({ 
  crawl: function(path) {
    var self = this;
    fs.readdir(path, function(err, files) {
      files.forEach(function(x) {
        fs.stat(x, function(err, stats) {
          if (stats.isFile() { self.emit('file', x); }
          if (stats.isDirectory()) { self.emit('dir', x); }
        });
      });
    });
  }
});

var fc = new FileCrawler();
fc.on('dir', function(dir) { this.crawl(dir); });

fc.on('file', function(file) {
  var self = this;
  // TODO this might hurt but makes coding so much easier
  // TODO assumes ascii
  fs.readFile(file, 'ascii', function(err, data) {
    // TODO strings are probably not efficient and buffers may help. start naive.
    // TODO feed whole file to a tokenizer
    data.split('.').forEach(function(x) {
      self.emit('line', file, x);
    });
  });
});

fc.on('line', function(file, line) {
  new mongodb.Db(mongo_db, mongos, {}).open(function(err, client) {
    var lines = new mongodb.Collection(client, 'lines');
    // TODO collect metadata
    lines.insert({
      'raw': line,
      'source': file
    }, function(err, docs) { client.close() });
  });
});
