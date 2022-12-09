import os

if paramCount() != 1:
    echo "Usage: ./day01 <input file>"
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
const STATE_LEN = 14
var state: Deque[char]
for i in 0..<STATE_LEN:
    assert(buffer[i] != '.')
    state.addFirst('.')

var index = 0;

for i, c in buffer:
    state.addFirst(c)
    discard state.popLast()
    assert state.len == STATE_LEN
    let state_set = state.toSeq.toHashSet
    if state_set.len == STATE_LEN and i > 3:
        index = i + 1
        break
assert index > 0

echo index