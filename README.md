                                   o
           _   ,_    __   ,   __,      __
         |/ \_/  |  /  \_/ \_/  |  |  /
         |__/    |_/\__/  \/ \_/|_/|_/\___/
        /|
        \|

## prosaic is a poetry generator

### summary

 * based on the [weltanschauung](https://github.com/nathanielksmith/weltanschauung) algorithm
 * directed cut-up over large corpora
 * two halves:
  * _nyarlarthotep_, reads, parses, tags text and stores in mongodb
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
 * largely intended for human collaborators; goal is for it to produce great works on its own
 * we waste millions of minutes filling the internet with junk text that will be lost forever. the tools of cutup/juxtaposition uncover works of beauty that we'd otherwise never see

### disclaimer

 * hacky art project
 * totally bizarre code style

### author

nathaniel k smith
<nathanielksmith@gmail.com>
