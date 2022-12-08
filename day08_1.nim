# import std/strutils
# import std/sequtils
# import std/random

let filename = "./data/test/day08_input.txt";
# let filename = "./data/full/day08_input.txt";

type
    Matrix[T: untyped, W, H:int] = seq[seq[T]]

proc newMatrix[T](W, H: int): Matrix[T, W, H] =
    result.newSeq(H)
    for i in 0 ..< H:
        result[i].newSeq(W)

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

for row in forest:
    echo row

type
    Direction = enum
        up, down, left, right

proc visibilityCheck[W, H](forest: Matrix[uint8, W, H], visible: var Matrix[bool, W, H], direction: Direction) = 
    case direction:
    of up, down:

        var f: proc(hi: int): int
        if direction == up:
            let N = len(forest) - 1
            f = proc(hi: int): int = N - hi
        else:
            f = proc(hi: int): int = hi

        for hi, row in forest:
            if hi == 0:
                for wi, _ in row:
                    visible[wi, f(hi)] = true
                continue
            var found_visible = false
            for wi, tree in row:
                if visible[wi, f(hi-1)]:
                    if tree > forest[wi, f(hi-1)]:
                        visible[wi, f(hi)] = true
                        found_visible = true
            if not found_visible:
                break

    of left, right:
        var f: proc(wi: int): int
        if direction == left:
            let N = len(forest[0]) - 1
            f = proc(wi: int): int = N - wi
        else:
            f = proc(wi: int): int = wi

        for wi, _ in forest[0]:
            if wi == 0:
                for hi, _ in forest:
                    visible[f(wi), hi] = true
                continue
            var found_visible = false
            for hi, row in forest:
                if visible[f(wi-1), hi]:
                    if row[f(wi)] > row[f(wi-1)]:
                        visible[f(wi), hi] = true
                        found_visible = true

for direction in [up, down]:
    visibilityCheck(forest, visible, direction)
# visibilityCheck(forest, visible, up)

for row in visible:
    for tree in row:
        if tree:
            write(stdout, "#")
        else:
            write(stdout, ".")
    write(stdout, "\n")