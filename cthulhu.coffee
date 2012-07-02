#!/usr/bin/env coffee
# cthulhu.coffee
# given json poem structure, produce a poem.
# implements the weltanschauung algorithm.

fs = require 'fs'

async = require 'async'
mg = require 'mongoose'

(require './prelude').install()
{Phrase} = require './idols'

randi = (max) -> Math.floor (Math.random() * max)

# type RuleSet = [Rule]
# type Line = Object
# type Query = Object

class Rule
    @trivial_clause: {}

    # RuleSet -> Query
    @collapse_ruleset: (ruleset) ->
        """
        Produce a single query feedable to Phrase.findOne() from a list of
        rules.
        """
        ((fold {}) extend) ((map (r)->r.clause()) ruleset)

    # RuleSet -> RuleSet
    @weaken_ruleset: (ruleset) ->
        """
        Given a ruleset, weaken a random rule in the set and return the
        ruleset.
        """
        index = randi (len ruleset)
        print "WEAKENING #{index}"
        ((filter (r) -> ((gt r.weakness) 0)) ruleset)[index]?.weaken()

        ruleset

    # Object -> RuleSet
    @line_to_rule: (line) ->
        ruleset = []
        if 'num_syllables' of line
            ruleset = ((front ruleset) new SyllableCountRule(line.num_syllables))
        # TODO more rules...
        if (eq (len ruleset)) 0
            ruleset = ((front ruleset) new Rule)

        ruleset

    # [RuleSet] -> [Line] -> (Error -> [RuleSet]) -> None
    @parse_rhymes: (rulesets) -> (lines) -> (cb) ->
        print 'parsing'
        print rulesets
        letters = (map (get 'rhyme')) lines
        unless (all letters)
            return cb null, rulesets
        print letters
        letter_to_sound = {}
        counter = 0
        print "LETTERS"
        print letters
        Phrase.find().distinct('rhyme_sound', (e, sounds) ->
            print 'got sounds'
            # side effects
            for letter in letters
                print letter
                unless letter_to_sound[letter]
                    letter_to_sound[letter] = sounds[randi (len sounds)]
                print letter_to_sound
                rulesets[counter] = (front rulesets[counter]) new LastPhonemeRule(letter_to_sound[letter])
                counter = (incr counter)
            cb(null, rulesets)
        )
    clause: ->
        sound = @.letter_to_phoneme[@.letters[@.letter_index]]
        @.letter_index = (mod (incr @.letter_index)) (len @.letters)
        ruleset
    constructor: ->
        @.weakness = 0
        @.clauses =
            '0': {}
    weaken: ->
        @.weakness = if @.weakness == 0 then 0 else (decr @.weakness)
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
                c[l] = (fac s) l # side effect
                ((gen_clauses c) s) (decr l)
        @.clauses = ((gen_clauses {}) syllables) syllables
        @.clauses[0] = Rule.trivial_clause

class LastPhonemeRule extends Rule
    constructor: (sound, cb) ->
        @.weakness = 3
        @.sound = sound
        @.clauses =
            3: rhyme_sound:sound
            2: rhyme_sound:
                if (match /0/) sound
                    ((replace /0/) sound) '1'
                else if (match /1/) sound
                    ((replace /1/) sound) '2'
                else if (match /2/) sound
                    ((replace /2/) sound) '0'
            1: rhyme_sound:
                if (match /0/) sound
                    ((replace /0/) sound) '2'
                else if (match /1/) sound
                    ((replace /1/) sound) '0'
                else if (match /2/) sound
                    ((replace /2/) sound) '1'
            0: Rule.trivial_clause

template_filename = process.argv[2] or process.exit(1)
dbname = process.argv[3] or 'prosaic'

mg.connect("mongodb://localhost/#{dbname}")

fs.readFile(template_filename, (err, data) ->
    (print err) if err
    (process.exit 2) if err

    lines = JSON.parse(data.toString()).lines
    rulesets = (map Rule.line_to_rule) lines
    ((Rule.parse_rhymes rulesets) lines) (e, rs) ->
        print rs
        rulesets = rs
        async.map(rulesets, (ruleset, cb) ->
            find_line = (ruleset) -> (cb) ->
                query = Rule.collapse_ruleset ruleset
                print query
                Phrase.find(query, ['stripped'], (e, phrases) ->
                    if empty phrases
                        (find_line (Rule.weaken_ruleset ruleset)) cb
                    else
                        cb null, phrases[randi (len phrases)].stripped
                )

            (find_line ruleset) cb
        , (e, poem) ->
            (console.error e) if e
            print poem
            process.exit()
        )
)
