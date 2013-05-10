#!/usr/bin/env coffee
# cthulhu.coffee
# given json poem structure, produce a poem.
# implements the weltanschauung algorithm.

fs = require 'fs'

async = require 'async'
mg = require 'mongoose'

(require './prelude').install()

{Phrase} = require './idols'
{Rule,
KeywordRule,
SyllableCountRule,
LastPhonemeRule} = require './rules'

template_filename = process.argv[2] or process.exit(1)
dbname = process.argv[3] or 'prosaic'

mg.connect "mongodb://localhost/#{dbname}"

fs.readFile(template_filename, (err, data) ->
    (print err) if err
    (process.exit 2) if err

    lines = JSON.parse(data.toString()).lines
    rulesets = (map Rule.line_to_rule) lines
    async.waterfall([
        (cb) -> cb null, rulesets, lines,
        KeywordRule.parse_keywords,
        LastPhonemeRule.parse_rhymes,
    ], (e, rulesets, lines) ->
        if e
            console.error e
            process.exit(2)

        async.map(rulesets, (ruleset, cb) ->
            find_line = (ruleset) -> (cb) ->
                query = Rule.collapse_ruleset ruleset
                print query
                Phrase.find(query, 'stripped source', (e, phrases) ->
                    if empty phrases
                        (find_line (Rule.weaken_ruleset ruleset)) cb
                    else
                        cb null, phrases[randi (len phrases)]
                )

            (find_line ruleset) cb
        , (e, poem) ->
            (console.error e) if e
            sources = (map (x) -> x.source) poem
            lines = (map (x) -> x.stripped) poem
            print sources
            print lines
            process.exit()
        )
    )
)
