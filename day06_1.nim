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
import std/deques
import std/sets

var buffer: string;
for line in lines(filename):
    if line[0] != '#':
        buffer = line;
        break;

assert buffer != ""

var state: Deque[char]
for i in 0..<4:
    assert(buffer[i] != '.')
    state.addFirst('.')

var index = 0;

for i, c in buffer:
    state.addFirst(c)
    discard state.popLast()
    assert state.len == 4
    let state_set = state.toSeq.toHashSet
    if state_set.len == 4 and i > 3:
        # echo i, ' ', state, ' ', state_set
        index = i + 1
        break
assert index > 0

echo index