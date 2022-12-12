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
import std/algorithm
import std/sequtils

var elves: seq[seq[int]] = @[];
var calories: seq[int] = @[];

for line in lines(filename):
    if line == "":
        elves.add(calories)
        calories = @[];
    else:
        calories.add(line.parseInt)

var snacks = map(elves, proc (x: seq[int]): int = x.foldl(a + b)).sorted;
# pick last 3 elements
var last3 = snacks[^3..^1];
echo last3.foldl(a + b)




