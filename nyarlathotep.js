// nyarlathotep.js
// * give file and target db
// * slurp file, send to azathoth

var fs = require('fs');
var net = require('net');

// TODO spec these
var azathoth_port = 9143;
var azathoth_host = 'localhost';
var filepath = process.argv[2];
var db = process.argv[3] || 'stijfveen';
var dry_run = process.argv[4] || false

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
    if (dry_run) {
        console.log(msg_json);
        return;
    }
    var client = net.createConnection(azathoth_port, azathoth_host);
    client.on('connect', function() {
        console.log('server connected');
        client.write(msg_json+'PROSAICFHTAGN\r\n');
        console.log('text sent');
    });
    client.on('data', function(data) {
        console.log('there');
        data = data.toString();
        if (data.match(/^OK/)) {
            process.exit(0);
        }
        else if (data.match(/^ERROR/)) {
            console.error(data);
            process.exit(3);
        }
    });
});
