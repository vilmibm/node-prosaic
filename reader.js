#!/usr/bin/env node
// given a directory
// process every file in the directory
// store a phrase in mongo-- {raw, source_filename, metadata}

var events = require('events');
var fs = require('fs');
var sys = require('sys');

var CMUDict = require('cmudict').CMUDict;
var mongodb = require('mongodb');

var mongo_port = 27017;
var mongo_db = 'noetry_dev';
var mongo_server = '127.0.0.1';
var mongos = new mongodb.Server(mongo_server, mongo_port, {});

var cmudict = new CMUDict();

function Phrase(string, file) {
  this.raw = string;
  this.num_sylls = 0;
  this.source = file;
  var phonemes = [];
  // trim off leading and trailing non letter/number anything
  function trim(string) {
    return string.replace(/^[^a-zA-Z0-9]+/, '').replace(/[^a-zA-Z0-9]+$/, '');
  }
  var words = string.split(/ +/);
  var vowelre = /AA|AE|AH|AO|AW|AY|IH|IY|OW|OY|UH|UW/;
  words.forEach(function(x) {
    var phonemic = cmudict.get(trim(x));
    if (phonemic) {
      var word_phonemes = phonemic.split(' ');
      phonemes.push(phonemes);
      word_phonemes.forEach(function(p) {
        if (p.match(vowelre)) { this.num_sylls++; }
      });
    }
  });
  this.phonemes = phonemes;
}

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
  this.cmudict = new CMUDict();
  this.on('dir', function(dir) { this.crawl(dir); });

  this.on('file', function(file) {
    var self = this;
    self.files_seen++;
    fs.readFile(file, 'utf8', function(err, data) {
      var t = new Tokenizer();
      t.on('phrase', function(match) {
        var p = new Phrase(match, file);
        self.phrases_seen++;
        var phrases = new mongodb.Collection(self.client, 'phrases');
        //var words = match.split(' ');
        //var num_sylls = 0;
        //var vowel_sounds = [
        //  'AA', 'AE', 'AH', 'AO', 'AW', 'AY', 'IH', 'IY', 'OW', 'OY', 'UH', 'UW'
        //];
        //function is_in(needle, haystack) {
        //  haystack.forEach(function(x) {
        //    if (x === needle) { return true; }
        //    return false;
        //  });
        //}
        //var sentence_phonemes = [];
        //words.forEach(function(w) {
        //  // TODO this mostly worksish but needs a sanitized version of the
        //  // string to work on. also syllable counting is borked.
        //  var phoneme_str = self.cmudict.get(w);
        //  if (phoneme_str) {
        //    var word_phonemes = phoneme_str.split(' ');
        //    sentence_phonemes.push(word_phonemes);
        //    word_phonemes.forEach(function(p) {
        //      if (is_in(p.substring(0,2), vowel_sounds)) { num_sylls++; }
        //    });
        //  } else {
        //    // TODO fallback syllable counter
        //  }
        //});
        //words[words.length-1]
        phrases.insert({
          'raw': p.raw,
          'phonemes': p.phonemes,
          'syllables': p.num_sylls,
          'source': p.source,
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
