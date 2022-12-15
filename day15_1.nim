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

type
    Point = tuple[x, y: int]

var data: seq[tuple[sensor: Point, beacon: Point]]

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

# for sensor, beacon in data.items:
#     echo "Sensor at ", sensor, " is closest to ", beacon

