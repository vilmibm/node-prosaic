net = require 'net'
sys = require 'sys'
CMUDict = require('cmudict').CMUDict
# mongoose
_ = require 'underscore'

mg = require('mongoose')
mg.connect('mongodb://localhost/prosaic_dev')
Schema = mg.Schema
ref = (model) -> {type:Schema.ObjectId, ref:model}

PhraseSchema = new Schema(
    source: {type:String, required:true}
    raw: {type:String}
)
# one giant stub

server = net.createServer((c) ->
    console.log 'client connected'
    buff = ''
    c.on('data', (data) ->
        buff += data.toString()
        match = buff.match(/(.*)PROSAICFHTAGN$/)
        if match
            try
                consume(match[1], c)
            catch e
                console.error "ERROR #{e}"
                connection.write "ERROR #{e}"
    )
    c.on('disconnect', -> console.log 'client disconnected')
)
server.listen(9143)

consume = (raw_json, connection) ->
    text = JSON.parse raw_json
    # make sure label and raw are in there, return error if not
    if 'label' not in _.keys(text) or 'raw' not in _.keys(text)
        throw 'missing label or raw'


