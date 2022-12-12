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

import strutils
import sequtils
import deques
import algorithm

type
    TestFun = proc (x: int): bool
    OpFun = proc (x: int): int

    Monkey = object
        items: Deque[int]
        operation: OpFun
        test: TestFun
        true_index: int
        false_index: int
    
    Op = enum
        plus, times

func parseOp(s: string): Op = 
    case s:
    of "*":
        result = times
    of "+":
        result = plus
    else:
        raise newException(ValueError, "Unknown operation" & $s)

func newMonkey(
    items: Deque[int],
    operation: OpFun,
    test: TestFun,
    true_index: int,
    false_index: int
): Monkey =
    result.items = items
    result.operation = operation
    result.test = test
    result.true_index = true_index
    result.false_index = false_index

var monkeys: seq[Monkey]

var line: string
const MONKEY_LINE = "Monkey"
const SITEM_LINE = "  Starting items:"
const OP_LINE = "  Operation: new = old"
const TEST_LINE = "  Test: divisible by"
const TEST_TRUE_LINE = "    If true: throw to monkey"
const TEST_FALSE_LINE = "    If false: throw to monkey"

func test_line(line, s: string): bool = result = line[0..<len(s)] == s
func strip_line(line, s: string): string = result = line[len(s)..^1].strip
let file: File = filename.open(fmRead)
try:
    while not endOfFile(file):
        line = readLine(file)
        if len(line) == 0 or line[0] == '#': continue
        if test_line(line, MONKEY_LINE):
            let monkey_number = strip_line(line, MONKEY_LINE)[0..^2].parseInt
            assert monkey_number == len(monkeys)

            line = readLine(file)
            assert test_line(line, SITEM_LINE)
            let items = strip_line(line, SITEM_LINE).split(", ").map(parseInt).toDeque

            line = readLine(file)
            assert test_line(line, OP_LINE)
            let op_line_split = strip_line(line, OP_LINE).split(' ')
            assert len(op_line_split) == 2
            let op = op_line_split[0].parseOp

            var operation: OpFun
            if op_line_split[1] == "old":
                case op:
                of times:
                    operation = proc (x:int): int = x * x
                of plus:
                    operation = proc (x:int): int = x + x
            else:
                closureScope:
                    let arg = op_line_split[1].parseInt
                    case op:
                    of times:
                        operation = proc (x:int): int = x * arg
                    of plus:
                        operation = proc (x:int): int = x + arg

            line = readLine(file)
            assert test_line(line, TEST_LINE)
            var test: TestFun
            closureScope:
                let test_mod = strip_line(line, TEST_LINE).parseInt
                test = proc (x: int): bool = x mod test_mod == 0

            line = readLine(file)
            assert test_line(line, TEST_TRUE_LINE)
            let true_index = strip_line(line, TEST_TRUE_LINE).parseInt

            line = readLine(file)
            assert test_line(line, TEST_FALSE_LINE)
            let false_index = strip_line(line, TEST_FALSE_LINE).parseInt

            monkeys.add(newMonkey(items, operation, test, true_index, false_index))

finally:
    file.close()

for monkey in monkeys.items:
    assert monkey.true_index < len(monkeys)
    assert monkey.false_index < len(monkeys)

var inspect_count = newSeq[int](len(monkeys))

for round_index in 0..<20:
    for monkey_index, m in monkeys.mpairs:
        while len(m.items) > 0:
            # Inspect the item
            let new_item = m.operation(m.items.popFirst()) div 3
            monkeys[if m.test(new_item): m.true_index else: m.false_index].items.addLast(new_item)
            inspect_count[monkey_index] += 1

for (monkey, count) in zip(monkeys, inspect_count):
    echo monkey.items, ' ', count

echo inspect_count.sorted[^2..^1].foldl(a*b)
