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
    @line_to_rule: (line) ->
        if 'num_syllables' of line
            new SyllableCountRule(line.num_syllables)
        else
            new Rule
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

mg.connect("mongodb://#{dbname}")

fs.readFile(template_filename, (err, data) ->
    (print err) if err
    (process.exit 2) if err

    lines = JSON.parse(data.toString()).lines
    rules = (map Rule.line_to_rule) lines

    async.map(rules, (rule, cb) ->
        cb null, 'GREAT JOB'
    , (e, poem) ->
        print poem
    )
)
