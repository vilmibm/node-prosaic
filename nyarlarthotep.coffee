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
phrase_toker = new natural.RegexpTokenizer(pattern:split_pattern)
word_toker = new natural.WordTokenizer()
metaphone = natural.Metaphone
metaphone.attach()

# helpers
head = (l) -> l[0]
tail = (l) -> l[1..]
len = (l) -> l.length
last = (l) -> if (len l) <= 1 then l.pop() else last (tail l)
gt = (x) -> (y) -> x > y

PhraseSchema = new mg.Schema(
    raw: {type:String, require:true}
    source: {type:String, require:true}
    line_no: Number
    last_sound: String
)
Phrase = mg.model('Phrase', PhraseSchema)
mg.connect("mongodb://localhost/#{dbname}")

fs.readFile(filename, (err, data) ->
    line_no = 0
    async.forEach(
        phrase_toker.tokenize(
            data.toString().split('*** END OF THIS PROJECT GUTENBERG')[0]
        )
        , (s, cb) ->
            return (cb null) unless (gt (len s)) 10
            line_no += 1
            s = s.replace(/[\r\n]+/g, ' ')
            words = word_toker.tokenize(s)
            phrase = new Phrase()
            phrase.raw = s
            phrase.source = filename
            phrase.line_no = line_no
            phrase.last_sound = (last words).phonetics()
            phrase.save(cb)
        , (err) ->
            console.error err if err
            process.exit(0)
    )
)
