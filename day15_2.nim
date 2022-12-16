import os

if paramCount() != 1:
    echo "Usage: ./dayXX <input file>"
    quit(1)
let filename = paramStr(1)
if not fileExists(filename):
    echo "File not found: ", filename
    quit(1)

## RUN: FULL
# RUN: TEST

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

#     echo "Sensor at ", sensor, " is closest to ", beacon

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

proc span(sp: seq[Point]): Span {.inline.} =
    result = MIN_SPAN
    for p in sp:
        result += p.span

proc draw(span: Span) =
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
    repr_string.add("\n")
    for j in 0..<span.height:
        let y = span[0, j].y
        let row_number = (if y < -9: $y elif y < 0: " " & $y elif y < 10: "  " & $y else: " " & $y) & " "
        repr_string.add(row_number)
        for i in 0..<span.width:
            let coords: Point = span[i, j]
            if coords in sensors:
                repr_string.add("S")
            elif coords in beacons:
                repr_string.add("B")
            else:
                let coord_distances = sensors.mapIt(abs(it - coords))
                let mask = zip(coord_distances, distances).mapIt(it[0] <= it[1])
                if mask.anyIt(it):
                    let sensors_with_index = zip(sensors, (0..<sensors.len).toSeq)
                    let closest_index = zip(sensors_with_index, mask).filterIt(it[1]).mapIt(it[0][1])
                    assert closest_index.len >= 1
                    let closest_index_letter = (closest_index[0] + ord('a')).chr
                    repr_string.add(closest_index_letter)
                else:
                    repr_string.add(".")
        repr_string.add("\n")
    echo repr_string

# let all_span = enclosing_points.span
let sensors_span = sensors.span

# draw(sensors_span)
# echo calc_not_allowed(all_span, 10)

func test(coordinate: Point, N: int, sensors: seq[Point], distances: seq[int]): bool = 
    var count = 0
    for i in 0..<N:
        count += (abs(sensors[i] - coordinate) <= distances[i]).int
    return count == 0
    
let N = sensors.len
echo N
var missing_beacon: Point = newPoint(0, 0)
block toplevel:
    for row in 0..sensors_span.height:
        for col in 0..sensors_span.width:
            let coords: Point = sensors_span[col, row]
            if test(coords, N, sensors, distances):
                missing_beacon = coords
                break toplevel

echo "missing_beacon: ", missing_beacon
assert missing_beacon.x != 0 and missing_beacon.y != 0
echo missing_beacon.x * 4000000 + missing_beacon.y

#     --------          11111111112
#     87654321012345678901234567890
# -10 ..........h..................
#  -9 .........hhh.................
#  -8 ........hhhhh................
#  -7 .......hhhhhhh...............
#  -6 ......hhhhhhhhh.............n
#  -5 .....hhhhhhhhhhh...........nn
#  -4 ....hhhhhhhhhhhhh.........nnn
#  -3 ...hhhhhhhhhhhhhhh.......nnnn
#  -2 ..hhhhhhhhhhhhhhghh.....nnnnn
#  -1 .hhhhhhhhhhhhhhggghh.c.nnnnnn
#   0 hhhhhhhhhhShhhggggghcccnnnnnn
#   1 .hhhhhhhhhhhhggggggcccccnnnnS
#   2 ..hhhhhhhhhhggggggcccScccnnnn
#   3 ...hhhhhhhhggggggggcccSBllnnn
#   4 ....hhhhhhggggggggggcccllllnn
#   5 .....hhhhggggggggggggcgglllln
#   6 ......hhggggggggggggggggglllj
#   7 .......gggggggggSgggggggSgljj
#   8 ........gggggggggggggggggljjj
#   9 .......iigggggggggggggggljjjj
#  10 ......iiiiBgggggggggdggljjjjj
#  11 .....iiiSiaggggggggddd.jjjjjj
#  12 ......iiiaaaggggggdddddjjjjjj
#  13 .......iaaaaaggggdddddddjjjjj
#  14 .......aaaaaaaggddddSddddjjjS
#  15 ......Baaaaaaaaggbddddddffjjj
#  16 .....aaaaaaaaaaabSBddddffffjj
#  17 ....aaaaaaaaaaaaabedddSfffffj
#  18 ...aaaaaaaSaaaaaaaeedffffffjj
#  19 ....aaaaaaaaaaaaaeeeeeffffjjj
#  20 .....aaaaaaaaaaaeeSeeeeffSjjj