import std/strutils
import std/sequtils
import std/algorithm

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

template sum[T](s: seq[T]): T = s.foldl(a + b)

var snacks = map(elves, proc (x: seq[int]): int = x.sum).sorted;
# pick last 3 elements
var last3 = snacks[^3..^1];
echo last3.sum




