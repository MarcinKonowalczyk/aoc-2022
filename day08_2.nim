import os

if paramCount() != 1:
    echo "Usage: ./day01 <input file>"
    quit(1)
let filename = paramStr(1)
if not fileExists(filename):
    echo "File not found: ", filename
    quit(1)

## RUN: TEST
# RUN: FULL

import std/strutils

type
    Matrix[T: untyped, W, H:int] = seq[seq[T]]

proc newMatrix[T](W, H: int): Matrix[T, W, H] =
    result.newSeq(H)
    for i in 0 ..< H:
        result[i].newSeq(W)

proc rows[T: untyped, W, H:int](m: Matrix[T, W, H]): int = result = len(m)
proc columns[T: untyped, W, H:int](m: Matrix[T, W, H]): int = result = len(m[0])

proc `[]`[T: untyped, W, H:int](m: Matrix[T, W, H], x, y: int): T =
    m[y][x]

proc `[]=`[T: untyped, W, H:int](m: var Matrix[T, W, H], x, y: int, value: T) =
    m[y][x] = value

# proc `*=`[T: untyped, W, H:int](m: var Matrix[T, W, H], x, y: int, value: T) =
#     m[y][x] *= value

proc parseInt(c: char): uint8 =
    assert(c in '0' .. '9')
    uint8(c.ord - 48)

var width = 0
var height = 0
var all_lines: seq[string]
for line in lines(filename):
    if len(all_lines) == 0:
        width = line.len
    else:
        assert(line.len == width)
    all_lines.add(line)
    height += 1

var forest = newMatrix[uint8](width, height)
for hi, line in all_lines:
    for wi, character in line:
        forest[wi, hi] = character.parseInt

var scenicity = newMatrix[int](width, height)
for hi in 0..<height:
    for wi in 0..<width:
        scenicity[wi, hi] = 1

type
    Direction = enum
        up, down, left, right

proc scenicCount[W, H](forest: Matrix[uint8, W, H], scenicity: var Matrix[int, W, H], direction: Direction) = 
    proc loopCore(wi, hi: int, distances: var auto, forest: auto, scenicity: var auto) =
        for i in 0..<10:
            distances[i] += 1
        let tree = forest[wi, hi]
        scenicity[wi, hi] = scenicity[wi, hi] * distances[tree]
        for i in 0..int(tree):
            distances[i] = 0

    case direction:
    of up, down:
        
        for wi in 0..<forest.columns:
            var distances: seq[int] = newSeq[int](10)
            for i in 0..<10:
                distances[i] = -1
            if direction == up:
                for hi in countdown(forest.rows-1, 0):
                    loopCore(wi, hi, distances, forest, scenicity)
            else:
                for hi in countup(0, forest.rows-1):
                    loopCore(wi, hi, distances, forest, scenicity)

    of left, right:

        for hi in 0..<forest.rows:
            var distances: seq[int] = newSeq[int](10)
            for i in 0..<10:
                distances[i] = -1
            if direction == left:
                for wi in countdown(forest.columns-1, 0):
                    loopCore(wi, hi, distances, forest, scenicity)
            else:
                for wi in countup(0, forest.columns-1):
                    loopCore(wi, hi, distances, forest, scenicity)
    
        

for direction in [up, down, left, right]:
    scenicCount(forest, scenicity, direction)

# const PRINT = true
const PRINT = false

var highest = 0
for hi in 0..<height:
    for wi in 0..<width:
        if PRINT:
            write(stdout, scenicity[wi, hi].toHex(2))
            write(stdout, " ")
        if scenicity[wi, hi] > highest:
            highest = scenicity[wi, hi]
    if PRINT: write(stdout, "\n")

echo highest