import std/strutils

# let filename = "./data/test/day04_input.txt";
let filename = "./data/full/day04_input.txt";

proc biject_string*(s: string, d: char): tuple =
    let split = s.split(d);
    assert split.len == 2
    result = (split[0], split[1])

# Have a look at https://stackoverflow.com/a/63802982/2531987 too ???

var data: seq[((int, int), (int, int))] = @[]
for line in lines(filename):
    let 
        split_line = biject_string(line, ',')
        elf1 = biject_string(split_line[0], '-')
        elf2 = biject_string(split_line[1], '-')
        parsed = (
            (elf1[0].parseInt, elf1[1].parseInt),
            (elf2[0].parseInt, elf2[1].parseInt)
        )
    data.add(parsed)

var count: int = 0

for (elf1, elf2) in data:
    if elf1[1] >= elf2[0] and elf1[0] <= elf2[1]:
        count += 1

echo count