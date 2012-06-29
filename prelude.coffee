_ = require 'underscore'

# (a -> b) -> (c -> a) -> (c -> b)
c = (f) -> (g) -> (a...) -> (f g.apply(null, a))

# [a] -> a
head = (l) -> l[0]

# [a] -> a
tail = (l) -> l[1..]

# (Num a) => [a] -> a
len = (x) -> x.length

# (Num a) => a -> [a] -> [a]
take_last = (n) -> (l) -> l[-n..]

# (Ord a,b) => a -> b -> Bool
gt = (x) -> (y) -> x > y

# (Ord a,b) => a -> b -> Bool
lt = (x) -> (y) -> x < y

# (a -> Bool) -> [a] -> [a]
filter = (p) -> (l) -> l.filter p

# (a -> b) -> [a] -> [b]
map = (f) -> (l) -> l.map f

# Regexp -> String -> Bool
match = (r) -> (s) -> (s.match r) != null

# a -> null
print = (a...) -> console.log.apply null, a

# TODO type specific hack here
# (a -> a -> a) -> [a] -> a
fold = (i) -> (f) -> (l) -> if (len l) then (l.reduce f,i) else i

# [a] -> a
sum = (fold 0) (x,y) -> x+y

# a -> a -> Bool
eq = (x) -> (y) -> x == y

# a -> a -> Bool
ne = (x) -> (y) -> x != y

# (Num a) => a -> a

decr = (x) -> x - 1

# a -> (b -> a) -> (b -> Maybe a) -- sort of
maybe = (d) -> (f) -> (a...) ->
    try
        f.apply null, a
    catch e
        d
maybe_num = maybe 0
maybe_list = maybe []

# (Eq a) => a -> [a] -> [[a]]
break_ = (s) -> (l) ->
    help = (l_) -> (r) ->
        if (eq (len r)) 0 # did not find
            [l_, r]
        else if (eq (head r)) s # found
            [l_, r]
        else # recur
            (help ((back l_) (head r))) (tail r)
    (help []) l

# (a -> Bool) -> [a] -> [[a]]
breakf = (f) -> (l) ->
    help = (l_) -> (r) ->
        if (eq (len r)) 0
            [l_, r]
        else if (f (head r))
            [l_, r]
        else
            (help ((back l_) (head r))) (tail r)
    (help []) l

# [a] -> a -> [a]
front = (l) -> (x) -> [x].concat(l)

# [a] -> a -> [a]
back = (l) -> (x) -> l.concat([x])

# [a] -> [a]
reverse = (l) ->
    help = (l_) -> (r) ->
        if (eq (len l_)) 0
            r
        else
            (help (tail l_)) ((front r) head l_)
    (help l) []

# [a] -> a
last = (c head) reverse

# [String] -> String -> String
join = (s) -> (l) -> l.join(s)

# Object -> Object -> Object
# extend = (x) -> (y) -> _.extend(x, y)
extend = (x,y) -> _.extend(x,y)

prelude =
    c:c
    head:head
    tail:tail
    len:len
    take_last:take_last
    gt:gt
    lt:lt
    filter:filter
    map:map
    match:match
    print:print
    fold:fold
    sum:sum
    eq:eq
    ne:ne
    maybe:maybe
    maybe_num: maybe_num
    maybe_list: maybe_list
    break_:break_
    breakf:breakf
    front:front
    back:back
    reverse:reverse
    last:last
    join:join
    extend:extend
    decr:decr

install = (target) -> (source) -> [target[k] = v for k,v of source]
(install exports) prelude
exports.install = -> (install global) prelude
