
import std/strutils
# import std/sets
include utils

# let filename = "./data/test/day03_input.txt";
let filename = "./data/full/day03_input.txt";


var backpacks: seq[array[2, string]] = @[];
for line in lines(filename):
    assert(len(line) mod 2 == 0)
    
    backpacks.add([
        line[0..(len(line) div 2-1)],
        line[len(line) div 2..len(line)-1],
    ])

var commons: seq[char] = @[];
for backpack in backpacks:
    let 
        left = backpack[0]
        right = backpack[1]
    assert(len(left) == len(right))
    var left_set, right_set: set[char]
    for c in left: left_set.incl(c)
    for c in right: right_set.incl(c)
    var common = left_set * right_set
    assert(len(common) == 1)
    for v in common: commons.add(v)

proc calculate_score(item: char): int =
    if ord(item) >= ord('a') and ord(item) <= ord('z'):
        return ord(item) - ord('a') + 1
    elif ord(item) >= ord('A') and ord(item) <= ord('Z'):
        return ord(item) - ord('A') + 27
    else:
        raise newException(ValueError, "Invalid item: " & $item)

let scores = commons.map(calculate_score)
echo scores.sum