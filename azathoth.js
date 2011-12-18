// azathoth.js
// * listen at some port
// * accept json data terminated by PROSAICFHTAGN
// * run through tokenizer/phraser and into mongodb

var net = require('net');
var EventEmitter = require('events').EventEmitter;

var CMUDict = require('cmudict').CMUDict;
var mongodb = require('mongodb');

var cmudict = new CMUDict();
var mongo_port = 27017;
var mongo_server = '127.0.0.1';
var mongos = new mongodb.Server(mongo_server, mongo_port, {});

var to_array = function to_array(thing) {
    return Array.prototype.slice.call(thing);
};

var server = net.createServer(function(c) {
    c.on('data', function(data) {
        var text_json = data.toString().match(/(.*)PROSAICFTHGAN/);
        if (!text_json) return;
        consume(text_json[1]);
    });
});
server.listen(9143, 'localhost');

function consume(json) {
    var text = '';
    try { text = JSON.parse(json); }
    catch (e) {
        console.error('Received malformed json');
        return;
    }
    var do_want = ['label', 'raw'];
    var failed = false;
    do_want.forEach(function(x) {
        if (!text[x]) {
            console.error('Received malformed json; missing key '+x);
            failed = true;
        }
    });
    if (failed) return;
    var p = Object.create(prosaic_parser).init();
    p.parse(text);
}

var prosaic_parser = {
    init: function() {
        this.phrases_in = 0;
        this.phrases_out = 0;
        return this;
    },
    parse: function(text_obj) {
        this.doc = {
            label: text_obj.label,
            db: (text_obj.db || 'stijfveen')
        };
        var that = this;
        new mongodb.Db(this.doc.db, mongos, {}).open(function(err, client) {
            if (err) {
                console.error(err);
                return;
            }
            that.client = client;
            var t = Object.create(prosaic_tokenizer).init();
            t.on('phrase', function(str) { that.handle_phrase.call(that, str) });
            t.write(text_obj.raw);
        });
    },
    handle_phrase: function(str) {
        this.phrases_in++;
        var phrase_doc = {
            raw: str,
            source: this.doc.label,
            // TODO num_sylls,
            // TODO source
            // TODO phoneme str
            // TODO end rhyme
        };
        var phrases = new mongodb.Collection(this.client, 'phrases');
        var that = this;
        phrases.insert(phrase_doc, function() {
            that.phrases_out++;
            if (that.phrases_out === that.phrases_in) {
                that.client.close();
            }
        });
    }
};

function implement_map(props, from, to) {
    props.forEach(function(p) {
        var func = function() {
            from[p].apply(from, to_array(arguments));
        };
        func.name = p;
        to[p] = func;
    });
}

var prosaic_tokenizer = {
    init: function() {
        this._buffer = '';
        var eventer = new EventEmitter();
        implement_map(['on', 'emit'], eventer, this);
        this.eventer = eventer;
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
