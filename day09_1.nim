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
import std/sets

type
    Direction = enum
        up, down, left, right

var path: seq[Direction] = @[]

for line in lines(filename):
    if line == "": continue
    if line[0] == '#': continue
    let split_line = line.split(" ")
    assert(split_line.len == 2)
    var direction: Direction
    case split_line[0]:
        of "U": direction = up
        of "D": direction = down
        of "L": direction = left
        of "R": direction = right
        else: assert(false)
    let distance = split_line[1].parseInt
    assert(distance > 0)
    for i in 0..<distance:
        path.add(direction)

type
    Point = tuple[x, y: int]

proc sign(x: int): int =
    if x > 0:
        return 1
    elif x < 0:
        return -1
    else:
        return 0
    
proc updateTail(head: Point, tail: var Point) =
    let
        dx = head.x - tail.x
        dy = head.y - tail.y
    
    if dx.abs > 1 or dy.abs > 1:
        if dx.abs == dy.abs:
            tail.x += dx.sign * (dx.abs - 1)
            tail.y += dy.sign * (dy.abs - 1)
        elif dx.abs > dy.abs:
            tail.y += dy.sign
            tail.x += dx.sign * (dx.abs - 1)
        else:
            tail.x += dx
            tail.y += dy.sign * (dy.abs - 1)

proc purple(s: string): string = "\e[0;34m" & s & "\e[0m"
proc darkgray(s: string): string = "\e[0;30m" & s & "\e[0m"
proc green(s: string): string = "\e[1;32m" & s & "\e[0m"
proc red(s: string): string = "\e[1;31m" & s & "\e[0m"

proc printPositions(head: Point, tail: Point, start: Point = Point((x: 0, y: 0))) =
    let
        x_max = [head.x, tail.x, start.x].max
        x_min = [head.x, tail.x, start.x].min
        y_max = [head.y, tail.y, start.y].max
        y_min = [head.y, tail.y, start.y].min
    
    for y in countdown(y_max, y_min):
        for x in countup(x_min, x_max):
            if x == head.x and y == head.y:
                stdout.write("H".green)
            elif x == tail.x and y == tail.y:
                stdout.write("T".red)
            elif x == start.x and y == start.y:
                stdout.write("s".purple)
            else:
                stdout.write(".".darkgray)
    
        stdout.write("\n")

var head = Point((x: 0, y: 0))
var tail = Point((x: 0, y: 0))

var visited: HashSet[Point] = initHashSet[Point]()
visited.incl(tail)

const PRINT = false
# const PRINT = true

if PRINT:
    printPositions(head, tail)
    echo ""

for step in path:
    case step:
        of up: head.y += 1
        of down: head.y -= 1
        of left: head.x -= 1
        of right: head.x += 1
    updateTail(head, tail)
    visited.incl(tail)
    if PRINT:
        printPositions(head, tail)
        echo ""

echo visited.len