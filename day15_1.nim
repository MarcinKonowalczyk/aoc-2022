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

type
    Point = tuple[x, y: int]

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

let all_span = enclosing_points.span

# var repr_string: string = ""
# for j in 0..<all_span.height:
#     for i in 0..<all_span.width:
#         let coords: Point = all_span[i, j]
#         if coords in sensors:
#             repr_string.add("S")
#         elif coords in beacons:
#             repr_string.add("B")
#         else:
#             let coord_distances = sensors.mapIt(abs(it - coords))
#             let mask = zip(coord_distances, distances).mapIt(it[0] <= it[1])
#             if mask.anyIt(it):
#                 let sensors_with_index = zip(sensors, (0..<sensors.len).toSeq)
#                 let closest_index = zip(sensors_with_index, mask).filterIt(it[1]).mapIt(it[0][1])
#                 assert closest_index.len >= 1
#                 let closest_index_letter = (closest_index[0] + ord('a')).chr
#                 repr_string.add(closest_index_letter)
#             else:
#                 repr_string.add(".")
#     repr_string.add("\n")
# echo repr_string

# const PROBE_ROW = 10
const PROBE_ROW = 2000000

var not_allowed: int = 0
for i in 0..all_span.width:
    let coords: Point = (all_span[i, 0].x, PROBE_ROW)
    for (sensor, closest) in zip(sensors, distances):
        if abs(sensor - coords) <= closest:
            let is_beacon = beacons.filterIt(it == coords).len > 0
            if not is_beacon:
                # echo sensor, " is closest to ", coords, " (", abs(sensor - coords), " <= ", closest, ")"
                not_allowed.inc
            break
    if i mod 100000 == 0:
        echo i, " / ", all_span.width, " not allowed: ", not_allowed

echo not_allowed