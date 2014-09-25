                                   o
           _   ,_    __   ,   __,      __
         |/ \_/  |  /  \_/ \_/  |  |  /
         |__/    |_/\__/  \/ \_/|_/|_/\___/
        /|
        \|

## prosaic is a poetry generator

# this is the old prosaic. There's a new version with actual documentation at: [https://github.com/nathanielksmith/prosaic](https://github.com/nathanielksmith/prosaic)

### summary

 * based on the [weltanschauung](https://github.com/nathanielksmith/weltanschauung) algorithm
 * directed cut-up poetry over large corpora
 * two halves:
  * _nyarlathotep_, reads, parses, tags text and stores in mongodb
  * _cthulhu_, given a poem template in JSON generate a cut-up piece

### usage

        wget http://www.gutenberg.org/cache/epub/31469/pg31469.txt
        ./nyarlarthotep.coffee pg31469.txt
        ./cthulhu.coffee templates/haiku.json
        [ 'How horrid you are',
          'Works of man cultivation',
          'Watching his water' ]
### but... why?

 * william burroughs had some good ideas
 * largely intended for human collaboration; the poems it puts out can be thought of as a starting point for further work. some corpora, however, cause beautiful works to be produced with little/no human intervention.
 * we waste millions of minutes filling the internet with junk text that will be lost forever. the tools of cutup/juxtaposition uncover works of beauty that we'd otherwise never see

### examples

i have published a few sonnets on [gnoetry daily](http://gnoetrydaily.wordpress.com/category/prosaic/).

### disclaimer

 * hacky art project
 * totally bizarre code style

### author

nathaniel k smith
<nathanielksmith@gmail.com>
