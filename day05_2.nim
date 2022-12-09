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

import std/strutils
import std/sequtils

let file: File = filename.open(fmRead);

var stack_lines = "";
var instruction_lines = "";

try:
    while true:
        let line = file.readLine();
        if line == "":
            break;
        stack_lines &= line & "\n";
    stack_lines = stack_lines[0 .. ^2];

    while not endOfFile(file):
        let line = file.readLine();
        instruction_lines &= line & "\n";
    instruction_lines = instruction_lines[0 .. ^2];
finally:
    file.close();

# Parse initial stack
let stack_line_len = stack_lines.split("\n")[^1].len + 1
assert(stack_line_len mod 4 == 0)
let n_stacks: uint = cast[uint](stack_line_len div 4)

type
    Stack = seq[char]
    Stacks = seq[Stack]

proc height(stack: Stack): int = 
    stack.len

proc reverse(s: Stack): Stack =
  result = newSeq[char](s.height)
  for i in 0 ..< s.len:
    result[i] = s[s.len - i - 1]

var stacks: Stacks = @[];
for i in 0 .. n_stacks-1:
    stacks.add(@[]);

proc print(stacks: Stacks) =
    var longest_stack = 0
    for stack in stacks:
        longest_stack = max(longest_stack, stack.len)
    
    for i in countdown(longest_stack-1, 0):
        for stack in stacks:
            if i < stack.len:
                stdout.write(stack[i])
            else:
                stdout.write('.')
        stdout.write("\n")

for line in stack_lines.split("\n")[0..^2]:
    for i in 0 .. n_stacks-1:
        let crate = line[i*4 + 1]
        if crate != ' ':
            stacks[i].add(crate)

stacks = stacks.map(proc (x: Stack): Stack = x.reverse())

# Parse instructions
var instructions: seq[tuple[src, dst, n: uint]] = @[];
for line in instruction_lines.split("\n"):
    let parts = line.split(" ")
    assert(parts.len == 6)
    let
        src = parts[3].parseUInt - 1
        dst = parts[5].parseUInt - 1
        n = parts[1].parseUInt
    assert(src != dst)
    assert(src <= n_stacks)
    assert(dst <= n_stacks)
    instructions.add((src, dst, n))

# Execute instructions
const PRINT = false;
for ins in instructions:
    if PRINT: stacks.print()
    var temp: Stack;
    for _ in 0 .. ins.n-1:
        if len(stacks[ins.src]) == 0:
            raise newException(ValueError, "Stack empty in an unexpected place!")
        temp.add(stacks[ins.src].pop())
    for _ in 0 .. ins.n-1:
        stacks[ins.dst].add(temp.pop())
    if PRINT: echo "---"
if PRINT: stacks.print()

# stacks.print()

# # Get the top crate for each stack
let final = stacks.map(proc(stack: seq[char]): char = stack[^1]).join("")
echo final
# 