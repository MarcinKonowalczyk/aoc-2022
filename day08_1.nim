# import std/strutils
import std/sequtils
# import std/random

# let filename = "./data/test/day08_input.txt";
let filename = "./data/full/day08_input.txt";

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

var visible = newMatrix[bool](width, height)

type
    Direction = enum
        up, down, left, right

# https://stackoverflow.com/a/35697846/2531987
template toClosure(it): auto = 
    iterator j: type(it) = 
        for i in it:
            yield i
    j

proc visibilityCheck[W, H](forest: Matrix[uint8, W, H], visible: var Matrix[bool, W, H], direction: Direction) = 
    case direction:
    of up, down:
        
        let counter = if direction == up:
            toClosure(countdown(forest.rows-1, 0))
        else:
            toClosure(countup(0, forest.rows-1))
        
        let first = if direction == up: forest.rows-1 else: 0

        var highest: seq[uint8] = newSeq[uint8](forest.columns)
        for hi in counter:
            let row = forest[hi]
            for wi, tree in row:
                if hi == first or tree > highest[wi]:
                    visible[wi, hi] = true
                    highest[wi] = tree

    of left, right:

        let counter = if direction == left:
            toClosure(countdown(forest.columns-1, 0))
        else:
            toClosure(countup(0, forest.columns-1))

        let first = if direction == left: forest.columns-1 else: 0

        var highest: seq[uint8] = newSeq[uint8](forest.rows)
        for wi in counter:
            for hi, row in forest:
                let tree = row[wi]
                if wi == first or tree > highest[hi]:
                    visible[wi, hi] = true
                    highest[hi] = tree

for direction in [up, down, left, right]:
    visibilityCheck(forest, visible, direction)

# const PRINT = true
const PRINT = false

proc purple(s: string): string = "\e[1;34m" & s & "\e[0m"
proc darkgray(s: string): string = "\e[0;30m" & s & "\e[0m"

var total = 0
for hi, row in forest:
    for wi, tree in row:
        let ts = $tree
        if not visible[wi, hi]:
            if PRINT: write(stdout, ts.purple)
        else:
            # total += int(tree)
            total += 1
            if PRINT: write(stdout, ts.darkgray)
    if PRINT: write(stdout, "\n")

echo total