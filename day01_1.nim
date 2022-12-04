import std/strutils

include utils

# let filename = "./data/test/day01_input.txt";
let filename = "./data/full/day01_input.txt";

var elves: seq[seq[int]] = @[];
var calories: seq[int] = @[];

for line in lines(filename):
    if line == "":
        elves.add(calories)
        calories = @[];
    else:
        calories.add(line.parseInt)

echo map(elves, proc (x: seq[int]): int = x.sum).max


