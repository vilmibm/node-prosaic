#!/usr/bin/env coffee
# cthulhu.coffee
# given json poem structure, produce a poem.
# implements the weltanschauung algorithm.

fs = require 'fs'

async = require 'async'
mg = require 'mongoose'

(require './prelude').install()
{Phrase} = require './idols'

class Rule
    @trivial_clause: {}
    @collapse_ruleset: ->
        # TODO
    @weaken_ruleset: ->
        # TODO
    @line_to_rule: (line) ->
        ruleset = []
        if 'num_syllables' of line
            (front ruleset) new SyllableCountRule(line.num_syllables)
        # TODO more rules...
        if (eq (len ruleset)) 0
            (front ruleset) new Rule
        ruleset
    constructor: ->
        @.weakness = 0
        @.clauses =
            '0': {}
    weaken: ->
        @.weakness = if @.weakness == 0 then 0 else @.weakness - 1
    clause: ->
        @.clauses[@.weakness]

class SyllableCountRule extends Rule
    constructor: (syllables) ->
        @.weakness = syllables
        fac = (s) -> (l) -> {
            num_syllables:
                $lte: s + (s-l)
                $gte: s - (s-l)
        }
        gen_clauses = (c) -> (s) -> (l) ->
            if l == 0
                c
            else
                c[l] = (fac s) l
                ((gen_clauses c) s) (l-1)
        @.clauses = ((gen_clauses {}) syllables) syllables
        @.clauses[0] = Rule.trivial_clause

template_filename = process.argv[2] or process.exit(1)
dbname = process.argv[3] or 'prosaic'

mg.connect("mongodb://localhost/#{dbname}")

fs.readFile(template_filename, (err, data) ->
    (print err) if err
    (process.exit 2) if err

    lines = JSON.parse(data.toString()).lines
    rulesets = (map Rule.line_to_rule) lines

    async.map(rulesets, (ruleset, cb) ->
        # TODO random attribute siliness
        # TODO collapse ruleset into single query
        find_line = (ruleset) -> (cb) ->
            Phrase.findOne((Rule.collapse_ruleset ruleset), (e, phrase) ->
                if phrase
                    cb null, phrase
                else
                    (find_line (Rule.weaken_ruleset ruleset)) cb
            )
        (find_line ruleset) cb
    , (e, poem) ->
        (console.error e) if e
        print poem
        process.exit()
    )
)
