import os

if paramCount() != 1:
    echo "Usage: ./dayXX <input file>"
    quit(1)
let filename = paramStr(1)
if not fileExists(filename):
    echo "File not found: ", filename
    quit(1)

# RUN: FULL
## RUN: TEST

import strutils
import deques

type
    Matrix[T: untyped, W, H:int] = seq[seq[T]]
    Point = tuple[x, y: int]

func newMatrix[T](W, H: int): Matrix[T, W, H] =
    result.newSeq(H)
    for i in 0 ..< H:
        result[i].newSeq(W)

func `[]`[T: untyped, W, H:int](m: Matrix[T, W, H], x, y: int): T =
    m[y][x]

func `[]=`[T: untyped, W, H:int](m: var Matrix[T, W, H], x, y: int, value: T) =
    m[y][x] = value

func `[]`[T: untyped, W, H:int](m: Matrix[T, W, H], p: Point): T =
    m[p.y][p.x]

func `[]=`[T: untyped, W, H:int](m: var Matrix[T, W, H], p: Point, value: T) =
    m[p.y][p.x] = value

var width, height: int = 0
var lines: seq[string]
var i = 0
for line in lines(filename):
    if i == 0:
        width = line.len
    else:
        assert line.len == width
    lines.add(line)
    i += 1
height = lines.len

var map = newMatrix[int](width, height)
var start: Point = (0, 0)
var top: Point = (0, 0)

const CHAR_ORIGIN = ord('a')

for i, line in lines:
    for j, c in line:
        case c:
        of 'S':
            map[j, i] = ord('a') - CHAR_ORIGIN
            start = (j, i)
        of 'E':
            map[j, i] = ord('z') - CHAR_ORIGIN
            top = (j, i)
        else:
            assert (c in 'a' .. 'z')
            map[j, i] = ord(c) - CHAR_ORIGIN

import strformat

proc echo(m: Matrix[int, width, height]) =
    for row in m:
        for height in row:
            write(stdout, fmt"{height:2} ")
        write(stdout, "\n")

var distance = newMatrix[int](width, height)
let max_distance = width * height + 1

for i, row in distance:
    for j, height in row:
        distance[j, i] = max_distance

iterator getNeighbours(p: Point): Point =
    if p.x > 0:
        yield (p.x - 1, p.y)
    if p.x < width - 1:
        yield (p.x + 1, p.y)
    if p.y > 0:
        yield (p.x, p.y - 1)
    if p.y < height - 1:
        yield (p.x, p.y + 1)

var queue: Deque[tuple[p: Point, d: int]]
queue.addLast((start, 0))

while queue.len > 0:
    let (p, d) = queue.popFirst()
    if d < distance[p]:
        # Found a new shortest path. Update the distance map and propagate to neighbours.
        distance[p] = d
        for n in getNeighbours(p):
            if map[n] - map[p] <= 1:
                queue.addLast((n, d + 1))

if false:
    echo map
    echo ""
    echo distance
    echo ""

echo distance[top]
