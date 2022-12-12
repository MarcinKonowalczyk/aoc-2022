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

import std/strutils

type
    Command = enum
        noop, addx

var command_buffer: seq[tuple[cmd: Command, arg: int]]

for line in lines(filename):
    if len(line) == 0 or line[0] == '#': continue
    let split_line = line.split(' ')
    case split_line[0]:
    of "noop":
        assert len(split_line) == 1
        command_buffer.add((noop, 0))
    of "addx":
        assert len(split_line) == 2
        let arg = split_line[1].parseInt
        command_buffer.add((addx, arg))

# echo command_buffer

var X = 1
var cycle_count = 1
var total_signal_strength = 0

proc cycle_callback() = 
    if (cycle_count - 20) mod 40 == 0:
        let signal_strength = cycle_count * X
        total_signal_strength += signal_strength
        # echo cycle_count, " x ", X, " = ", signal_strength
    cycle_count += 1

for cmd, arg in command_buffer.items:
    if cmd == noop:
        cycle_callback()
    else:
        cycle_callback()
        cycle_callback()
        X += arg

echo total_signal_strength
