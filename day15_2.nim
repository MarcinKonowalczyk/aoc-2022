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

import re
import sequtils
import strutils

type Point = tuple[x, y: int]

func newPoint(x, y: int): Point {.inline.} = (x: x, y: y)

var data: seq[tuple[sensor: Point, beacon: Point]]

func `+`(a, b: Point): Point {.inline.} = (a.x + b.x, a.y + b.y)
func `+=`(a: var Point, b: Point) {.inline.} = a = a + b
func `-`(a, b: Point): Point {.inline.} = (a.x - b.x, a.y - b.y)
func `-=`(a: var Point, b: Point) {.inline.} = a = a - b
func abs(a: Point): int {.inline.} = abs(a.x) + abs(a.y)
func `*`(a, b: Point): Point {.inline.} = (a.x * b.x, a.y * b.y)

for line in lines(filename):
    var matches: array[4, string]
    # Sensor at x=2, y=18: closest beacon is at x=-2, y=15
    if not match(line, re"Sensor at x=([+-]?\d+), y=([+-]?\d+): closest beacon is at x=([+-]?\d+), y=([+-]?\d+)", matches):
        echo "Invalid line: ", line
        quit(1)
    let parsed_matches = matches.toSeq.map(parseInt)
    data.add((
        sensor: (x: parsed_matches[0], y: parsed_matches[1]),
        beacon: (x: parsed_matches[2], y: parsed_matches[3])
    ))

var
    enclosing_points: seq[Point]
    sensors: seq[Point]
    beacons: seq[Point]
    distances: seq[int]

for sensor, beacon in data.items:
    enclosing_points.add(sensor)
    enclosing_points.add(beacon)

    let distance = abs(sensor - beacon)
    enclosing_points.add(sensor + newPoint(-distance, 0))
    enclosing_points.add(sensor + newPoint(distance, 0))
    enclosing_points.add(sensor + newPoint(0, -distance))
    enclosing_points.add(sensor + newPoint(0, distance))

    distances.add(distance)
    sensors.add(sensor)
    beacons.add(beacon)

##==================================
##                                  
##   ####  #####    ###    ##   ##
##  ##     ##  ##  ## ##   ###  ##
##   ###   #####  ##   ##  #### ##
##     ##  ##     #######  ## ####
##  ####   ##     ##   ##  ##  ###
##                                  
##==================================

const INT_MAX = int.high
const INT_MIN = int.low
type Span = tuple[x1, x2, y1, y2: int]
const MIN_SPAN: Span = (INT_MAX, INT_MIN, INT_MAX, INT_MIN)

func span(p: Point): Span {.inline.} = (p.x, p.x, p.y, p.y)
func `+`(a, b: Span): Span {.inline.} = (min(a.x1, b.x1), max(a.x2, b.x2), min(a.y1, b.y1), max(a.y2, b.y2))
func `+=`(a: var Span, b: Span) {.inline.} = a = a + b
func `-`(a: Span, b: Point): Span {.inline.} = (a.x1 - b.x, a.x2 - b.x, a.y1 - b.y, a.y2 - b.y)
func `-=`(a: var Span, b: Point) {.inline.} = a = a - b
func width(s: Span): int {.inline.} = s.x2 - s.x1 + 1
func height(s: Span): int {.inline.} = s.y2 - s.y1 + 1
func `[]`(s: Span, x, y: int): Point {.inline.} = (s.x1 + x, s.y1 + y)
func `in`(p: Point, s: Span): bool {.inline.} = p.x >= s.x1 and p.x <= s.x2 and p.y >= s.y1 and p.y <= s.y2
proc span(sp: seq[Point]): Span {.inline.} =
    result = MIN_SPAN
    for p in sp:
        result += p.span

# let all_span = enclosing_points.span
# let sensors_span = sensors.span

# draw(sensors_span)
# echo calc_not_allowed(all_span, 10)

# import std/sets

const
    UP_RIGHT = newPoint(1,-1)
    DOWN_LEFT = newPoint(-1,1)
    UP_LEFT = newPoint(-1,-1)
    DOWN_RIGHT = newPoint(1,1)
    
func circumference(point: Point, sensor: Point): seq[Point] = 
    let d = point - sensor
    assert not (d.x == 0 and d.y == 0)
    var current = sensor + newPoint(abs(d)+1, 0)
    # Walk up and left until d.x = 0
    while abs(current.x - sensor.x) > 0:
        current += UP_LEFT
        result.add(current)
    # Walk down and left until d.x = 0
    while abs(current.y - sensor.y) > 0:
        current += DOWN_LEFT
        result.add(current)
    # Walk down and right until d.y = 0
    while abs(current.x - sensor.x) > 0:
        current += DOWN_RIGHT
        result.add(current)
    # Walk up and right until d.x = 0
    while abs(current.y - sensor.y) > 0:
        current += UP_RIGHT
        result.add(current)

const search_span: Span = (0, 4000000, 0, 4000000)
# const search_span: Span = (0, 20, 0, 20)

var circs: seq[seq[Point]] = @[]
var candidates: seq[Point] = @[]
for (sensor, beacon) in zip(sensors, beacons):
    let circ = circumference(beacon, sensor)
    circs.add(circ)
    for p in circ:
        if p in search_span:
            candidates.add(p)
    echo "added ", circ.len, " points for ", sensor, " -> ", beacon

proc draw(span: Span, candidates: seq[Point] = @[]) =
    var repr_string: string = ""
    repr_string.add("    ")
    for i in 0..<span.width:
        let x = span[i, 0].x
        let col_number = if x < 0: "-" elif x < 10: " " else: $(x div 10)
        repr_string.add(col_number)
    repr_string.add("\n    ")
    for i in 0..<span.width:
        let x = span[i, 0].x
        let col_number = if x < 0: $(-x) elif x < 10: $x else: $(x mod 10)
        repr_string.add(col_number)
    repr_string.add("\n    ")
    for i in 0..<span.width:
        repr_string.add(" ")
    repr_string.add("\n")
    for j in 0..<span.height:
        let y = span[0, j].y
        let row_number = (if y < -9: $y elif y < 0: " " & $y elif y < 10: "  " & $y else: " " & $y) & " "
        repr_string.add(row_number)
        for i in 0..<span.width:
            let coords: Point = span[i, j]
            if coords in sensors:
                repr_string.add("S")
            elif coords in candidates:
                repr_string.add("c")
            elif coords == newPoint(14, 11):
                repr_string.add("X")
            else:
                var found = false
                for circ in circs:
                    if coords in circ:
                        repr_string.add("o")
                        found = true
                        break
                if not found:
                    found = false
                    for (sensor, distance) in zip(sensors, distances):
                        if abs(coords - sensor) <= distance:
                            repr_string.add("#")
                            # repr_string.add(".")
                            found = true
                            break
                    if not found:
                        repr_string.add(".")
                
        repr_string.add("\n")
    echo repr_string

# draw(all_span)

func test(coordinate: Point, N: int, sensors: seq[Point], distances: seq[int]): bool = 
    var count = 0
    for i in 0..<N:
        count += (abs(sensors[i] - coordinate) <= distances[i]).int
    return count == 0

let N = len(sensors)
var missing_beacon = newPoint(0, 0)
let M = candidates.len
echo M, " candidates to test"
for i, candidate in candidates:
    if test(candidate, N, sensors, distances):
        missing_beacon = candidate
        break
    if i mod 100000 == 0:
        echo i, "/", M, " candidates tested"

assert missing_beacon.x != 0 and missing_beacon.y != 0
echo missing_beacon.x * 4000000 + missing_beacon.y

#     --------          1111111111222222222
#     8765432101234567890123456789012345678
                                         
# -10 ..........i..........................
#  -9 .........###.........................
#  -8 ........#####........................
#  -7 .......#######.......................
#  -6 ......#########.............#........
#  -5 .....###########...........###.......
#  -4 ....#############.........####i......
#  -3 ...###############.......#######.....
#  -2 ..#################.....#########....
#  -1 .###################.#.##########i...
#   0 i#########S#########i##############..
#   1 .##################i########S#######.
#   2 ..###################Si############..
#   3 ...##################iSB##########...
#   4 ....##################i##########....
#   5 .....###########################.....
#   6 ......##############i#####i####......
#   7 .......#########S#######S#####.......
#   8 ........####################i##......
#   9 .......##i###############i######.....
#  10 ......####B######################....
#  11 .....###S#############Xi#i########...
#  12 ......i###############i############..
#  13 .......i#####i#######i##############.
#  14 .......i############S#######S########
#  15 ......B##########i##################.
#  16 .....###########iSB####i###########..
#  17 ....#############i####S##########B...
#  18 ...#######S##########i####i######....
#  19 ....###########################i.....
#  20 .....#########i###S###i##S######.....
#  21 ......########i########i#######......
#  22 .......######i..#############B.......
#  23 ........#####....###..#######........
#  24 .........###......i....####i.........
#  25 ..........#.............###..........
#  26 .........................#...........