import os

if paramCount() != 1:
    echo "Usage: ./dayXX <input file>"
    quit(1)
let filename = paramStr(1)
if not fileExists(filename):
    echo "File not found: ", filename
    quit(1)

## RUN: TEST
# RUN: FULL

import std/strutils
import std/sequtils

type
    play = enum
        rock, paper, scissors

proc parseEnum(s: char): play =
    case s
    of 'A': rock
    of 'B': paper
    of 'C': scissors
    of 'X': rock
    of 'Y': paper
    of 'Z': scissors
    else: raise newException(ValueError, "Invalid play: " & s)

var strategy: seq[array[2, play]] = @[]
for line in lines(filename):
    let parts = line.split(" ").map(proc (x: string): char = x[0]);
    strategy.add([parseEnum(parts[0]), parseEnum(parts[1])])

proc result(x,y: play): int =
    case x
    of rock:
        case y
        of rock: 3
        of paper: 6
        of scissors: 0
    of paper:
        case y
        of rock: 0
        of paper: 3
        of scissors: 6
    of scissors:
        case y
        of rock: 6
        of paper: 0
        of scissors: 3

let bonus: array[play, int] = [1,2,3]

var scores = seq[int](@[])
for game in strategy:
    scores.add(result(game[0], game[1]) + bonus[game[1]])

echo scores.foldl(a + b)
