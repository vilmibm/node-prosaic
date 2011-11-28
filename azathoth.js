// azathoth.js
// * listen at some port
// * accept json data terminated by PROSAICFHTAGN
// * run through tokenizer/phraser and into mongodb

var net = require('net');

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
        var doc = this.doc(text_obj.label, text_obj.db);
    },
    doc: function(label, db) {
        return {
            label: label,
            db: (db || 'stijfveen')
        };
    }
};
