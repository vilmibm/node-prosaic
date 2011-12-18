// nyarlathotep.js
// * give file and target db
// * slurp file, send to azathoth

var fs = require('fs');
var net = require('net');

var azathoth_port = 9143;
var azathoth_host = 'localhost';
var filepath = process.argv[1];
var db = process.argv[2] || 'stijfveen';

if (!filepath) {
    console.error('no filepath supplied');
    process.exit(1);
}

fs.readFile(filepath, 'utf8', function(err, data) {
    if (err) {
        console.error(err);
        process.exit(2);
    }
    var message = {
       label: filepath,
       raw: data.toString(),
       db: db
    };
    var msg_json = JSON.stringify(message);
    var client = net.connect(azathoth_port, azathoth_host, function() {
        client.write(msg_json+'PROSAICFTHGAN\r\n');
    });
    client.on('data', function(data) {
        data = data.toString();
        if (data.match(/^OK/)) {
            process.exit(0);
        }
        else if (data.match(/^ERROR/)) {
            console.error(data);
            process.exit(3);
        }
    });
};
