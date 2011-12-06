// azathoth.js
// * listen at some port
// * accept json data terminated by PROSAICFHTAGN
// * run through tokenizer/phraser and into mongodb

var net = require('net');
var EventEmitter = require('events').EventEmitter;
var CMUDict = require('cmudict').CMUDict;
var cmudict = new CMUDict();

var server = net.createServer(function(c) {
    c.on('data', function(data) {
        var text_json = data.match(/(.*)PROSAICFTHGAN/);
        if (!text_json) return;
        consume(text_json);
    });
});
server.listen(9143, 'localhost');

function consume(json) {
    var text = JSON.parse(json);
    var do_want = ['label', 'raw'];
    do_want.forEach(function(x) {
        if (!text[x]) {
            console.error('Received malformed json; missing key '+x);
        }
    });
    var p = Object.create(prosaic_parser);
    p.parse(text);
}

var prosaic_parser = {
    parse: function(text_obj) {
        this.doc = {
            label: text_obj.label,
            db: (db || 'stijfveen')
        };
        var t = Object.create(prosaic_tokenizer).init();
        var that = this;
        t.on('phrase', function(str) { this.handle_phrase.call(that, str) });
        // TODO init a mongo client
        // TODO use .end() to clean up mongo client
        t.write(text_obj.raw);
    },
    handle_phrase: function(str) {
        var phrase_doc = {
            raw: str,
            source: label,
            // TODO num_sylls,
            // TODO source
            // TODO phoneme str
            // TODO end rhyme
        };
        // TODO connect to this.doc.db
        // TODO insert phrase_doc
    }
};

var prosaic_tokenizer = {
    init: function() {
       this._buffer = '';
       events.EventEmitter.call(this);
       return this;
    },
    write: function(data) {
        for (var c in data) {
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
    }
};
