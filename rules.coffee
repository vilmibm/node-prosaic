natural = require 'natural'

(require './prelude').install()

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
        ((filter (r) -> ((gt r.weakness) 0)) ruleset)[index]?.weaken()

        ruleset

    # Object -> RuleSet
    @line_to_rule: (line) ->
        print line
        # hate that it has to know about its child classes
        ruleset = []
        if 'num_syllables' of line
            ruleset = ((front ruleset) new SyllableCountRule(line.num_syllables))

        if 'keyword' of line
            ruleset = ((front ruleset) new KeywordRule(natural.PorterStemmer.stem line.keyword))

        if (eq (len ruleset)) 0
            ruleset = ((front ruleset) new Rule)

        ruleset

    # [RuleSet] -> [Line] -> (Error -> [RuleSet]) -> None
    @parse_rhymes: (rulesets) -> (lines) -> (cb) ->
        letters = (map (get 'rhyme')) lines
        unless (all letters)
            return cb null, rulesets
        letter_to_sound = {}
        counter = 0
        Phrase.find().distinct('rhyme_sound', (e, sounds) ->
            # side effects
            for letter in letters
                unless letter_to_sound[letter]
                    letter_to_sound[letter] = sounds[randi (len sounds)]
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


class KeywordRule extends Rule
    constructor: (keyword) ->
        @.keyword = keyword
        @.weakness = 11
        @.clauses =
            11: stems:keyword
            0: Rule.trivial_clause
    clause: -> 
        #if @.weakness in [0, 11]
        if @.weakness in [0]
            super
        else
            $where:"""
            var query = {stems:'#{@.keyword}'};

            var matches = db.phrases.find(query).count()
            if (matches === 0)
                return false;

            var phrases = db.phrases.find(query);
            return true;
            var phrase = phrases[Math.floor(Math.random()*matches)];

            if (phrase.source !== this.source)
                return false;

            var distance = Math.abs(phrase.line_no - this.line_no);

            if (distance > #{@.weakness})
                return false;

            return true;"""


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


exports.Rule = Rule
exports.KeywordRule = KeywordRule
exports.LastPhonemeRule = LastPhonemeRule
exports.SyllableCountRule = SyllableCountRule
