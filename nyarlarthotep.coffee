#!/usr/bin/env coffee
# nyarlarthotep.coffee
# read named file, put in database
fs = require 'fs'

async = require 'async'
mg = require 'mongoose'
natural = require 'natural'

filename = process.argv[2] or throw 'need filename'
dbname = process.argv[3] or 'prosaic'
split_pattern = /[\.,!?;]/
tokenizer = new natural.RegexpTokenizer(pattern:split_pattern)
PhraseSchema = new mg.Schema(
    raw: {type:String, require:true}
    source: {type:String, require:true}
)
Phrase = mg.model('Phrase', PhraseSchema)
mg.connect("mongodb://localhost/#{dbname}")

fs.readFile(filename, (err, data) ->
    async.forEach(
        tokenizer.tokenize(
            data.toString().split('*** END OF THIS PROJECT GUTENBERG')[0]
        )
        , (s, cb) ->
            return cb(null) if s.length <= 10
            s = s.replace(/[\r\n]+/g, ' ')
            phrase = new Phrase()
            phrase.raw = s
            phrase.source = filename
            phrase.save(cb)
        , (err) ->
            console.error err if err
            process.exit(0)
    )
)
