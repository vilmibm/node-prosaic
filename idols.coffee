# idols.coffee
# mongoose models
mg = require 'mongoose'

PhraseSchema = new mg.Schema(
    raw: {type:String, require:true}
    source: {type:String, required:true}
    stripped: String
    line_no: Number
    last_sound: String
    rhyme_sound: String
    num_syllables: Number
    tokens: [String]
)
exports.Phrase = mg.model('Phrase', PhraseSchema)
