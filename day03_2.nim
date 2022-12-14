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

import std/sequtils

var groups: seq[array[3, set[char]]] = @[];
var group: array[3, set[char]];
var i = 0;
for line in lines(filename):
    group[i] = {}
    for c in line: group[i].incl(c)
    i += 1
    if i == 3:
        groups.add(group)
        i = 0

var commons: seq[char] = @[];
for group in groups:
    let common = group[0] * group[1] * group[2]
    assert(common.len == 1)
    for c in common: commons.add(c)

proc calculate_score(item: char): int =
    if ord(item) >= ord('a') and ord(item) <= ord('z'):
        return ord(item) - ord('a') + 1
    elif ord(item) >= ord('A') and ord(item) <= ord('Z'):
        return ord(item) - ord('A') + 27
    else:
        raise newException(ValueError, "Invalid item: " & $item)

let scores = commons.map(calculate_score)
echo scores.foldl(a + b)