# import std/strutils
import std/sequtils
import std/deques
import std/sets

# let filename = "./data/test/day06_input.txt";
let filename = "./data/full/day06_input.txt";

var buffer: string;
for line in lines(filename):
    if line[0] != '#':
        buffer = line;
        break;

assert buffer != ""
const state_len = 14
var state: Deque[char]
for i in 0..<state_len:
    assert(buffer[i] != '.')
    state.addFirst('.')

var index = 0;

for i, c in buffer:
    state.addFirst(c)
    discard state.popLast()
    assert state.len == state_len
    let state_set = state.toSeq.toHashSet
    if state_set.len == state_len and i > 3:
        index = i + 1
        break
assert index > 0

echo index