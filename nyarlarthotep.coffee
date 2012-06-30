#!/usr/bin/env coffee
# nyarlarthotep.coffee
# read named file, put in database
fs = require 'fs'

async = require 'async'
{CMUDict} = require 'cmudict'
mg = require 'mongoose'
natural = require 'natural'

(require './prelude').install()
{Phrase} = require './idols'

filename = process.argv[2] or throw 'need filename'
dbname = process.argv[3] or 'prosaic'
vowel_re = /AA|AE|AH|AO|AW|AY|EH|EY|ER|IH|IY|OW|OY|UH|UW/
split_pattern = /[\.,!?;]/
phrase_toker = new natural.RegexpTokenizer(pattern:split_pattern)
word_toker = new natural.WordTokenizer()
metaphone = natural.Metaphone
metaphone.attach()
cmudict = new CMUDict()

# type Phoneme = String
# type Word = String
# Word -> [Phoneme]
phonemes = (w) ->
    ph_string = cmudict.get(w)
    if ph_string then ph_string.split ' ' else throw 'word not found'

# Word -> Num
count_syllables = (w) ->
    if w then (len ((filter (match vowel_re)) (phonemes w))) else 0

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
            return (cb null) if (empty words)
            phrase = new Phrase(
                raw: s
                stripped: (join ' ') words
                source: filename
                line_no: line_no
                last_sound: (last words).phonetics()
                num_syllables: sum ((map (maybe_num count_syllables)) words)
                rhyme_sound: ((join ' ') ((take_last 3) ((maybe_list phonemes) (last words))))
            )
            phrase.save(cb)
        , (err) ->
            console.error err if err
            process.exit(0)
    )
)
